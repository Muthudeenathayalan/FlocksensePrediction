import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/health/data/escalation_service.dart';
import 'package:flock_sense/features/health/data/health_service.dart';
import 'package:flock_sense/features/health/data/lab_test_service.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/lab_test_model.dart';
import 'package:flock_sense/features/health/domain/vet_assignment_model.dart';
import 'package:flock_sense/features/settings/domain/settings_providers.dart';

/// Clean model representing isolated Veterinarian Clinical Dashboard state
class VeterinarianDashboardState {
  final List<VetAssignmentModel> assignments;
  final List<LabTestModel> labTests;
  final List<HealthCaseModel> allCases;
  final int criticalCount;
  final int pendingReviewCount;
  final int underInvestigationCount;
  final int labResultsReadyCount;
  final int followUpsDueCount;
  final int resolvedTodayCount;
  final String activeDistrict;
  final String activeVetId;
  final String defaultSort;
  final bool isLoading;

  const VeterinarianDashboardState({
    this.assignments = const [],
    this.labTests = const [],
    this.allCases = const [],
    this.criticalCount = 0,
    this.pendingReviewCount = 0,
    this.underInvestigationCount = 0,
    this.labResultsReadyCount = 0,
    this.followUpsDueCount = 0,
    this.resolvedTodayCount = 0,
    this.activeDistrict = 'Nashik Division',
    this.activeVetId = 'vet_dr_sharma',
    this.defaultSort = 'Priority First',
    this.isLoading = false,
  });

  /// Priority-sorted assignments based on clinician preference
  List<VetAssignmentModel> get sortedQueue {
    final list = List<VetAssignmentModel>.from(assignments);
    if (defaultSort == 'Newest First') {
      list.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
    } else if (defaultSort == 'Oldest Waiting First') {
      list.sort((a, b) => a.assignedAt.compareTo(b.assignedAt));
    } else {
      // Default: Priority Score desc, then oldest waiting first
      list.sort((a, b) {
        final scoreComp = b.priorityScore.compareTo(a.priorityScore);
        if (scoreComp != 0) return scoreComp;
        return a.assignedAt.compareTo(b.assignedAt);
      });
    }
    return list;
  }
}

/// Clinical priority queue stream provider
final vetPriorityQueueStreamProvider = StreamProvider.autoDispose.family<List<VetAssignmentModel>, String>((ref, vetId) {
  return EscalationService.streamVetPriorityQueue(vetId: vetId);
});

/// Diagnostic lab tests stream provider
final vetLabTestsStreamProvider = StreamProvider.autoDispose<List<LabTestModel>>((ref) {
  return LabTestService.streamAllLabRequests();
});

/// Clinical health cases stream provider
final vetHealthCasesStreamProvider = StreamProvider.autoDispose<List<HealthCaseModel>>((ref) {
  return HealthService.streamHealthCases();
});

/// Dedicated Veterinarian Dashboard Provider
final veterinarianDashboardProvider = Provider.autoDispose.family<VeterinarianDashboardState, String?>((ref, overrideVetId) {
  final user = ref.watch(currentUserProvider);
  final activeVetId = overrideVetId ?? user?.uid ?? 'vet_dr_sharma';
  final prefs = ref.watch(settingsNotifierProvider);

  final assignAsync = ref.watch(vetPriorityQueueStreamProvider(activeVetId));
  final labAsync = ref.watch(vetLabTestsStreamProvider);
  final caseAsync = ref.watch(vetHealthCasesStreamProvider);

  final isLoading = assignAsync.isLoading || labAsync.isLoading || caseAsync.isLoading;
  final assignments = assignAsync.value ?? <VetAssignmentModel>[];
  final labTests = labAsync.value ?? <LabTestModel>[];
  final allCases = caseAsync.value ?? <HealthCaseModel>[];

  final criticalCount = assignments.where((a) => a.priorityLevel == VetPriorityLevel.critical).length;
  final pendingReviewCount = assignments.where((a) => a.status == VetAssignmentStatus.pending || a.status == VetAssignmentStatus.unassigned).length;
  final underInvestigationCount = allCases.where((c) => c.status == HealthCaseStatus.under_investigation).length;
  final labResultsReadyCount = labTests.where((t) => t.status == LabTestStatus.result_available).length;
  final followUpsDueCount = allCases.where((c) => c.status == HealthCaseStatus.treatment_started || c.status == HealthCaseStatus.monitoring).length;
  final resolvedTodayCount = allCases.where((c) => c.status == HealthCaseStatus.closed).length;

  return VeterinarianDashboardState(
    assignments: assignments,
    labTests: labTests,
    allCases: allCases,
    criticalCount: criticalCount,
    pendingReviewCount: pendingReviewCount,
    underInvestigationCount: underInvestigationCount,
    labResultsReadyCount: labResultsReadyCount,
    followUpsDueCount: followUpsDueCount,
    resolvedTodayCount: resolvedTodayCount,
    activeDistrict: prefs.serviceDistrict.isNotEmpty ? prefs.serviceDistrict : 'Nashik Division',
    activeVetId: activeVetId,
    defaultSort: prefs.defaultCaseSort,
    isLoading: isLoading,
  );
});
