import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

export const ESCALATION_ENGINE_VERSION = 'escalation-v1';

export interface EscalationEngineInput {
  caseId: string;
  caseNumber?: string;
  riskScore: number;
  riskLevel: 'low' | 'moderate' | 'high' | 'critical';
  farmId: string;
  farmName?: string;
  batchId: string;
  flockName?: string;
  farmerId?: string;
  district?: string;
  symptoms: string[];
  mortalityCount: number;
  affectedCount: number;
  riskReasons: string[];
  imageUrls?: string[];
  reportedAt?: Date;
}

export interface EscalationResult {
  escalated: boolean;
  caseId: string;
  escalationStatus: 'escalated' | 'district_queued' | 'monitoring_only' | 'warning_only';
  alertId?: string;
  assignmentId?: string;
  vetId?: string;
  districtQueue?: string;
  priorityScore: number;
  priorityLevel: 'critical' | 'urgent' | 'priority' | 'routine';
  farmerNotificationId?: string;
  vetNotificationId?: string;
  fcmSentCount: number;
}

/**
 * Calculate Priority Score distinct from Health Risk Score (SIH26128 Phase 5)
 */
export function calculatePriorityScore(input: EscalationEngineInput): { score: number; level: 'critical' | 'urgent' | 'priority' | 'routine' } {
  let score = 0;

  // 1. Base score from Risk Level
  if (input.riskLevel === 'critical') {
    score += 60;
  } else if (input.riskLevel === 'high') {
    score += 40;
  } else if (input.riskLevel === 'moderate') {
    score += 20;
  } else {
    score += 5;
  }

  // 2. Mortality severity modifier
  if (input.mortalityCount >= 15) {
    score += 20;
  } else if (input.mortalityCount >= 10) {
    score += 15;
  } else if (input.mortalityCount >= 5) {
    score += 10;
  } else if (input.mortalityCount > 0) {
    score += 5;
  }

  // 3. Affected flock proportion modifier
  if (input.affectedCount >= 100) {
    score += 15;
  } else if (input.affectedCount >= 50) {
    score += 10;
  } else if (input.affectedCount >= 20) {
    score += 5;
  }

  // 4. Acute spike / Sudden anomaly modifier
  const hasSpikeReason = input.riskReasons.some(r =>
    r.toLowerCase().includes('spike') ||
    r.toLowerCase().includes('anomaly') ||
    r.toLowerCase().includes('critical') ||
    r.toLowerCase().includes('sudden')
  );
  if (hasSpikeReason || input.mortalityCount >= 10) {
    score += 10;
  }

  // Bound to 0 - 100
  const finalScore = Math.min(100, Math.max(0, score));

  // Determine Priority Level
  let level: 'critical' | 'urgent' | 'priority' | 'routine' = 'routine';
  if (finalScore >= 75 || input.riskLevel === 'critical') {
    level = 'critical';
  } else if (finalScore >= 55 || input.riskLevel === 'high') {
    level = 'urgent';
  } else if (finalScore >= 35 || input.riskLevel === 'moderate') {
    level = 'priority';
  } else {
    level = 'routine';
  }

  return { score: finalScore, level };
}

/**
 * Dispatches an FCM Push Notification safely with invalid token cleanup
 */
async function sendFcmNotification(
  userId: string,
  fcmToken: string | undefined,
  title: string,
  body: string,
  route: string,
  db: admin.firestore.Firestore
): Promise<boolean> {
  if (!fcmToken || typeof fcmToken !== 'string' || fcmToken.trim().length === 0) {
    return false;
  }

  try {
    const payload: admin.messaging.Message = {
      token: fcmToken,
      notification: {
        title,
        body,
      },
      data: {
        route,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      webpush: {
        notification: {
          title,
          body,
          icon: '/icons/Icon-192.png',
        },
        fcmOptions: {
          link: route,
        },
      },
    };

    await admin.messaging().send(payload);

    await db.collection('audit_logs').add({
      operation: 'notification',
      resourceType: 'FCMNotification',
      resourceId: userId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      changes: {
        action: 'FCM_NOTIFICATION_SENT',
        userId,
        title,
      },
    });

    return true;
  } catch (err: any) {
    functions.logger.warn(`[FCM] Failed to send notification to user ${userId}:`, err?.message || err);

    // If token is invalid/unregistered, clean it up from the user document safely
    if (
      err?.code === 'messaging/invalid-registration-token' ||
      err?.code === 'messaging/registration-token-not-registered'
    ) {
      try {
        await db.collection('users').doc(userId).update({
          fcmToken: admin.firestore.FieldValue.delete(),
          tokenUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }

    await db.collection('audit_logs').add({
      operation: 'notification',
      resourceType: 'FCMNotification',
      resourceId: userId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      changes: {
        action: 'FCM_NOTIFICATION_FAILED',
        userId,
        error: err?.message || 'Unknown FCM error',
      },
    });

    return false;
  }
}

/**
 * Main Central Health Escalation Engine (SIH26128 Phase 5)
 */
export async function evaluateHealthEscalation(
  input: EscalationEngineInput,
  db: admin.firestore.Firestore
): Promise<EscalationResult> {
  const { score: priorityScore, level: priorityLevel } = calculatePriorityScore(input);

  // Policy check: LOW & MODERATE do not trigger urgent veterinary queue
  if (input.riskLevel === 'low') {
    functions.logger.info(`[EscalationEngine] Case ${input.caseId} is LOW risk. No escalation required.`);
    return {
      escalated: false,
      caseId: input.caseId,
      escalationStatus: 'monitoring_only',
      priorityScore,
      priorityLevel,
      fcmSentCount: 0,
    };
  }

  if (input.riskLevel === 'moderate') {
    functions.logger.info(`[EscalationEngine] Case ${input.caseId} is MODERATE risk. Farmer warning only.`);

    // Create farmer warning notification
    const warningNotifId = `notif_${input.caseId}_mod_${Date.now()}`;
    const warningTitle = `Flock Health Advisory: ${input.flockName || 'Flock'}`;
    const warningBody = `Moderate health anomaly score (${input.riskScore}/100) detected. Continue active twice-daily monitoring.`;

    if (input.farmerId) {
      await db.collection('users').doc(input.farmerId).collection('notifications').doc(warningNotifId).set({
        id: warningNotifId,
        title: warningTitle,
        body: warningBody,
        type: 'ai',
        priority: 'normal',
        status: 'unread',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        relatedFarmId: input.farmId,
        relatedBatchId: input.batchId,
        actionUrl: `/health/cases/${input.caseId}`,
        metadata: {
          caseId: input.caseId,
          riskScore: input.riskScore,
          riskLevel: input.riskLevel,
        },
      }, { merge: true });
    }

    return {
      escalated: false,
      caseId: input.caseId,
      escalationStatus: 'warning_only',
      priorityScore,
      priorityLevel,
      farmerNotificationId: warningNotifId,
      fcmSentCount: 0,
    };
  }

  // HIGH or CRITICAL -> Full Automatic Escalation Pipeline
  functions.logger.info(`[EscalationEngine] Escalating case ${input.caseId} (${input.riskLevel.toUpperCase()}, priority: ${priorityScore} ${priorityLevel})`);

  let fcmSentCount = 0;
  const now = new Date();
  const district = (input.district || 'Nashik').trim();

  // 1. Veterinarian Discovery in District
  let assignedVetId = '';
  let assignedVetName = '';
  let assignedVetFcmToken: string | undefined;

  try {
    const vetQuerySnap = await db.collection('users')
      .where('role', '==', 'veterinarian')
      .where('active', '==', true)
      .limit(10)
      .get();

    let matchedVet: admin.firestore.QueryDocumentSnapshot | null = null;

    vetQuerySnap.forEach(doc => {
      const data = doc.data();
      if (!matchedVet) {
        if (data.district && data.district.toLowerCase() === district.toLowerCase()) {
          matchedVet = doc;
        }
      }
    });

    // If exact district match not found, take first active vet as fallback or leave unassigned
    if (matchedVet) {
      const vData = (matchedVet as admin.firestore.QueryDocumentSnapshot).data();
      assignedVetId = (matchedVet as admin.firestore.QueryDocumentSnapshot).id;
      assignedVetName = vData.displayName || vData.name || 'District Veterinarian';
      assignedVetFcmToken = vData.fcmToken;
    }
  } catch (vetErr) {
    functions.logger.warn(`[EscalationEngine] Error discovering veterinarian for district ${district}:`, vetErr);
  }

  const isAssigned = assignedVetId.length > 0;
  const assignmentMethod = isAssigned ? 'automatic_district' : 'queue';
  const escalationStatus = isAssigned ? 'vet_assigned' : 'district_queued';

  // 2. Create / Update Disease Alert (Idempotent via deduplicationKey)
  const alertId = `alert_${input.caseId}_${input.riskLevel}_${ESCALATION_ENGINE_VERSION}`;
  const alertTitle = input.riskLevel === 'critical'
    ? 'CRITICAL ANIMAL HEALTH ALERT'
    : 'High Health Risk Detected';

  const cleanReasons = input.riskReasons.slice(0, 3).join(' • ');
  const alertMessage = `${input.farmName || 'Farm'} • Batch ${input.flockName || input.batchId} — Risk Score: ${input.riskScore}/100. ${cleanReasons}. Veterinary review recommended.`;

  const diseaseAlertDoc = {
    id: alertId,
    caseId: input.caseId,
    farmId: input.farmId,
    batchId: input.batchId,
    type: input.riskLevel === 'critical' ? 'critical_health_risk' : 'health_risk',
    severity: input.riskLevel,
    title: alertTitle,
    message: alertMessage,
    recipientRoles: ['farmer', 'veterinarian', 'government'],
    read: false,
    resolved: false,
    deduplicationKey: `${input.caseId}_${input.riskLevel}_${ESCALATION_ENGINE_VERSION}`,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  // 3. Create / Update Vet Assignment (Enforce ONE active assignment per case)
  const assignmentId = `va_${input.caseId}_${ESCALATION_ENGINE_VERSION}`;
  const vetAssignmentDoc = {
    id: assignmentId,
    caseId: input.caseId,
    caseNumber: input.caseNumber || `HC-${input.caseId.substring(0, 6)}`,
    vetId: assignedVetId,
    vetName: assignedVetName || (isAssigned ? 'Assigned Veterinarian' : 'Unassigned (District Queue)'),
    farmId: input.farmId,
    farmName: input.farmName || 'Poultry Facility',
    flockId: input.batchId,
    flockName: input.flockName || 'Batch',
    district: district,
    districtQueue: isAssigned ? null : district,
    priority: input.riskLevel,
    priorityScore: priorityScore,
    priorityLevel: priorityLevel,
    status: isAssigned ? 'pending' : 'unassigned',
    assignmentMethod: assignmentMethod,
    mortalityCount: input.mortalityCount,
    affectedCount: input.affectedCount,
    symptoms: input.symptoms,
    assignedAt: admin.firestore.FieldValue.serverTimestamp(),
    deduplicationKey: `${input.caseId}_assignment_${ESCALATION_ENGINE_VERSION}`,
  };

  // 4. In-App Notifications
  const farmerNotifId = `notif_${input.caseId}_farmer_${ESCALATION_ENGINE_VERSION}`;
  const farmerTitle = input.riskLevel === 'critical'
    ? '🚨 Critical Health Case Escalated'
    : '⚠️ Health Case Escalated for Review';
  const farmerBody = isAssigned
    ? `Your health report for ${input.flockName || 'flock'} (${input.riskScore}/100) has been assigned to ${assignedVetName} for veterinary review.`
    : `Your health report for ${input.flockName || 'flock'} (${input.riskScore}/100) has been queued for district veterinary review.`;

  const vetNotifId = `notif_${input.caseId}_vet_${ESCALATION_ENGINE_VERSION}`;
  const vetTitle = input.riskLevel === 'critical'
    ? `🚨 CRITICAL CASE: ${input.farmName || 'Farm'}`
    : `⚠️ High Risk Case: ${input.farmName || 'Farm'}`;
  const vetBody = `Batch ${input.flockName || input.batchId} reported with ${input.riskScore}/100 risk (${input.mortalityCount} mortality, ${input.affectedCount} affected). Priority: ${priorityLevel.toUpperCase()}.`;

  // 5. Atomic Batch Execution for Database Consistency
  const batch = db.batch();

  // Update HealthCase status
  const caseRef = db.collection('health_cases').doc(input.caseId);
  batch.update(caseRef, {
    status: isAssigned ? 'vet_assigned' : 'vet_required',
    escalationStatus: escalationStatus,
    assignedVetId: assignedVetId || null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Write DiseaseAlert
  const alertRef = db.collection('disease_alerts').doc(alertId);
  batch.set(alertRef, {
    ...diseaseAlertDoc,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  // Write VetAssignment
  const assignmentRef = db.collection('vet_assignments').doc(assignmentId);
  batch.set(assignmentRef, vetAssignmentDoc, { merge: true });

  // Write Farmer In-App Notification
  if (input.farmerId) {
    const farmerNotifRef = db.collection('users').doc(input.farmerId).collection('notifications').doc(farmerNotifId);
    batch.set(farmerNotifRef, {
      id: farmerNotifId,
      title: farmerTitle,
      body: farmerBody,
      type: 'ai',
      priority: input.riskLevel === 'critical' ? 'critical' : 'high',
      status: 'unread',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      relatedFarmId: input.farmId,
      relatedBatchId: input.batchId,
      actionUrl: `/health/cases/${input.caseId}`,
      metadata: {
        caseId: input.caseId,
        riskScore: input.riskScore,
        riskLevel: input.riskLevel,
        assignedVetName: assignedVetName || null,
      },
    }, { merge: true });
  }

  // Write Vet In-App Notification (if assigned)
  if (assignedVetId) {
    const vetNotifRef = db.collection('users').doc(assignedVetId).collection('notifications').doc(vetNotifId);
    batch.set(vetNotifRef, {
      id: vetNotifId,
      title: vetTitle,
      body: vetBody,
      type: 'ai',
      priority: input.riskLevel === 'critical' ? 'critical' : 'high',
      status: 'unread',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      relatedFarmId: input.farmId,
      relatedBatchId: input.batchId,
      actionUrl: `/health/cases/${input.caseId}`,
      metadata: {
        caseId: input.caseId,
        riskScore: input.riskScore,
        riskLevel: input.riskLevel,
        priorityScore: priorityScore,
        priorityLevel: priorityLevel,
        mortalityCount: input.mortalityCount,
        affectedCount: input.affectedCount,
      },
    }, { merge: true });
  }

  // Commit batch
  await batch.commit();

  // 6. Write Audit Logs
  await db.collection('audit_logs').add({
    operation: 'dataSync',
    resourceType: 'HealthEscalation',
    resourceId: input.caseId,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    changes: {
      action: isAssigned ? 'HEALTH_CASE_ESCALATED' : 'VET_QUEUE_ESCALATED',
      caseId: input.caseId,
      riskLevel: input.riskLevel,
      priorityScore,
      priorityLevel,
      assignedVetId: assignedVetId || 'none_district_queue',
      district,
    },
  });

  await db.collection('audit_logs').add({
    operation: 'dataSync',
    resourceType: 'DiseaseAlert',
    resourceId: alertId,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    changes: {
      action: 'DISEASE_ALERT_CREATED',
      caseId: input.caseId,
      severity: input.riskLevel,
      title: alertTitle,
    },
  });

  await db.collection('audit_logs').add({
    operation: 'dataSync',
    resourceType: 'VetAssignment',
    resourceId: assignmentId,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    changes: {
      action: 'VET_ASSIGNMENT_CREATED',
      caseId: input.caseId,
      vetId: assignedVetId || 'district_queue',
      priorityLevel,
      priorityScore,
      assignmentMethod,
    },
  });

  // 7. Dispatch FCM Push Notifications (Non-blocking & Resilient)
  if (input.farmerId) {
    try {
      const farmerUserSnap = await db.collection('users').doc(input.farmerId).get();
      const farmerFcmToken = farmerUserSnap.data()?.fcmToken;
      const sent = await sendFcmNotification(
        input.farmerId,
        farmerFcmToken,
        farmerTitle,
        farmerBody,
        `/health/cases/${input.caseId}`,
        db
      );
      if (sent) fcmSentCount++;
    } catch (_) {}
  }

  if (assignedVetId && assignedVetFcmToken) {
    try {
      const sent = await sendFcmNotification(
        assignedVetId,
        assignedVetFcmToken,
        vetTitle,
        vetBody,
        `/health/cases/${input.caseId}`,
        db
      );
      if (sent) fcmSentCount++;
    } catch (_) {}
  }

  functions.logger.info(`[EscalationEngine] Completed escalation for case ${input.caseId}. FCM sent: ${fcmSentCount}`);

  return {
    escalated: true,
    caseId: input.caseId,
    escalationStatus,
    alertId,
    assignmentId,
    vetId: assignedVetId || undefined,
    districtQueue: isAssigned ? undefined : district,
    priorityScore,
    priorityLevel,
    farmerNotificationId: farmerNotifId,
    vetNotificationId: assignedVetId ? vetNotifId : undefined,
    fcmSentCount,
  };
}
