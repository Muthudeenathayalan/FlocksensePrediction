import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { calculateHealthRisk, computeInputHash, RiskEngineInput } from './health/riskEngine';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Cloud Function Trigger on HealthCase creation or update (SIH26128)
 * Evaluates rule + historical anomaly risk engine and updates assessment
 */
export const onHealthCaseChanged = functions.firestore
  .document('health_cases/{caseId}')
  .onWrite(async (change, context) => {
    const caseId = context.params.caseId;

    // 1. If document was deleted, exit
    if (!change.after.exists) {
      return null;
    }

    const data = change.after.data();
    if (!data) return null;

    // 2. Prevent Trigger Loops: Compare input hash
    const input: RiskEngineInput = {
      caseId,
      farmId: data.farmId || '',
      batchId: data.flockId || data.batchId || '',
      currentMortality: data.mortalityCount || 0,
      affectedCount: data.affectedCount || 0,
      symptoms: data.symptoms || [],
      feedReductionPercent: data.feedReductionPercent,
      waterReductionPercent: data.waterReductionPercent,
      temperature: data.temperature,
      humidity: data.humidity,
      incidentDate: data.reportedAt ? data.reportedAt.toDate() : new Date(),
    };

    const currentInputHash = computeInputHash(input);

    // 3. Fetch existing assessment to prevent duplicate recalculation loops
    const assessmentRef = db.collection('risk_assessments').doc(`${caseId}_risk-v1`);
    const existingSnap = await assessmentRef.get();

    if (existingSnap.exists) {
      const existingData = existingSnap.data();
      if (existingData && existingData.inputHash === currentInputHash) {
        // Hash unchanged, no health input was modified (e.g. read status or vet note updated)
        return null;
      }
    }

    try {
      // 4. Fetch 7-day daily records for the same batch
      const dailyRecordsSnap = await db
        .collection('users')
        .doc(data.farmerId || 'local_user')
        .collection('farms')
        .doc(data.farmId)
        .collection('batches')
        .doc(data.flockId || data.batchId)
        .collection('dailyRecords')
        .orderBy('recordDate', 'desc')
        .limit(7)
        .get();

      const mortalities: number[] = [];
      dailyRecordsSnap.forEach(doc => {
        const d = doc.data();
        if (d && typeof d.mortalityCount === 'number') {
          mortalities.push(d.mortalityCount);
        }
      });
      input.recentDailyMortalities = mortalities;

      // 5. Calculate Risk Score & Explainable Reasons
      const assessment = calculateHealthRisk(input);

      // 6. Write RiskAssessment Document
      await assessmentRef.set({
        ...assessment,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      // 7. Update HealthCase with Official Risk Results
      const updatedStatus = (assessment.riskLevel === 'high' || assessment.riskLevel === 'critical')
        ? 'vet_required'
        : (data.status === 'reported' ? 'risk_assessed' : data.status);

      await db.collection('health_cases').doc(caseId).update({
        riskScore: assessment.score,
        riskLevel: assessment.riskLevel,
        riskReasons: assessment.reasons,
        status: updatedStatus,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 8. Write Audit Log for Risk Assessment
      await db.collection('audit_logs').add({
        operation: 'dataSync',
        resourceType: 'RiskAssessment',
        resourceId: assessment.id,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        changes: {
          action: 'RISK_ASSESSED',
          caseId,
          score: assessment.score,
          riskLevel: assessment.riskLevel,
          engineVersion: assessment.engineVersion,
        },
      });

      // 8b. Central Health Escalation Engine (SIH26128 Phase 5) - NEVER WAITS FOR AI
      try {
        const { evaluateHealthEscalation } = await import('./health/escalationEngine');
        await evaluateHealthEscalation({
          caseId,
          caseNumber: data.caseNumber,
          riskScore: assessment.score,
          riskLevel: assessment.riskLevel,
          farmId: data.farmId || '',
          farmName: data.farmName,
          batchId: data.flockId || data.batchId || '',
          flockName: data.flockName || data.batchName,
          farmerId: data.farmerId || data.userId,
          district: data.district || 'Nashik',
          symptoms: data.symptoms || [],
          mortalityCount: data.mortalityCount || 0,
          affectedCount: data.affectedCount || 0,
          riskReasons: assessment.reasons || [],
          imageUrls: data.imageUrls || data.images || [],
          reportedAt: data.reportedAt ? data.reportedAt.toDate() : new Date(),
        }, db);
      } catch (escErr) {
        functions.logger.error(`[EscalationEngine] Error escalating case ${caseId}:`, escErr);
      }

      // 9. Multimodal AI Clinical Decision Support Evaluation (SIH26128 Phase 4)
      try {
        const { evaluateAIHealthAssessment, computeAIInputHash, AI_PROMPT_VERSION } = await import('./health/aiAssessmentEngine');
        const aiDocRef = db.collection('ai_health_assessments').doc(`${caseId}_${AI_PROMPT_VERSION}`);

        const aiInput = {
          caseId,
          farmId: data.farmId || '',
          batchId: data.flockId || data.batchId || '',
          riskAssessmentId: assessment.id,
          species: data.species || 'poultry',
          flockBreed: data.flockName || data.batchName || 'Commercial Broiler',
          symptoms: data.symptoms || [],
          affectedCount: data.affectedCount || 0,
          mortalityCount: data.mortalityCount || 0,
          notes: data.notes || '',
          feedReductionPercent: data.feedReductionPercent,
          waterReductionPercent: data.waterReductionPercent,
          temperature: data.temperature,
          humidity: data.humidity,
          riskScore: assessment.score,
          riskLevel: assessment.riskLevel,
          riskReasons: assessment.reasons,
          recentDailyMortalities: mortalities,
          vaccineStatus: data.vaccineConcern || 'Routine broiler schedule',
          imageUrls: data.imageUrls || data.images || [],
          promptVersion: AI_PROMPT_VERSION,
        };

        const aiHash = computeAIInputHash(aiInput);
        const existingAiSnap = await aiDocRef.get();
        let shouldRunAi = true;

        if (existingAiSnap.exists) {
          const existingAiData = existingAiSnap.data();
          if (existingAiData && existingAiData.inputHash === aiHash && existingAiData.status === 'completed') {
            shouldRunAi = false;
          }
        }

        if (shouldRunAi) {
          // Set status = processing
          await aiDocRef.set({
            caseId,
            farmId: aiInput.farmId,
            batchId: aiInput.batchId,
            riskAssessmentId: assessment.id,
            status: 'processing',
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });

          const aiResult = await evaluateAIHealthAssessment(aiInput);

          await aiDocRef.set({
            ...aiResult,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });

          // Update HealthCase possibleDiseases for backward compatibility
          if (aiResult.possibleConditions && aiResult.possibleConditions.length > 0) {
            await db.collection('health_cases').doc(caseId).update({
              possibleDiseases: aiResult.possibleConditions.map(c => c.name),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          }

          // Audit log for AI Assessment
          await db.collection('audit_logs').add({
            operation: 'dataSync',
            resourceType: 'AIHealthAssessment',
            resourceId: aiResult.id,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            changes: {
              action: aiResult.status === 'completed' ? 'AI_HEALTH_ASSESSMENT_COMPLETED' : 'AI_HEALTH_ASSESSMENT_FAILED',
              caseId,
              modelName: aiResult.modelName,
              promptVersion: aiResult.promptVersion,
              conditionsCount: aiResult.possibleConditions.length,
              urgency: aiResult.urgency,
            },
          });
        }
      } catch (aiErr) {
        functions.logger.error(`[AIHealthAssessment] Error processing AI for case ${caseId}:`, aiErr);
      }

      functions.logger.info(`[RiskEngine] Successfully evaluated case ${caseId}: ${assessment.riskLevel} (${assessment.score}/100)`);
      return true;
    } catch (error) {
      functions.logger.error(`[RiskEngine] Error processing case ${caseId}:`, error);
      return null;
    }
  });
