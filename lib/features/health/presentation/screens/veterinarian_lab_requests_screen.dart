import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/app_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/core/widgets/web_page_header.dart';
import 'package:flock_sense/features/health/data/lab_test_service.dart';
import 'package:flock_sense/features/health/domain/lab_test_model.dart';

/// Dedicated Screen for Diagnostic Lab Sample Requests (SIH26128)
class VeterinarianLabRequestsScreen extends StatefulWidget {
  const VeterinarianLabRequestsScreen({super.key});

  @override
  State<VeterinarianLabRequestsScreen> createState() => _VeterinarianLabRequestsScreenState();
}

class _VeterinarianLabRequestsScreenState extends State<VeterinarianLabRequestsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LabTestModel>>(
      stream: LabTestService.streamAllLabRequests(),
      builder: (context, snapshot) {
        final tests = snapshot.data ?? [];
        final filtered = tests.where((t) {
          return t.sampleId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.caseId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.testRequested.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WebPageHeader(
                title: 'Laboratory Diagnostic Requests & Sample Pipeline',
                subtitle: 'Diagnostic sample chain-of-custody, cold-chain receipt verification, and testing queues',
              ),

              // Search bar
              AppCard(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search diagnostic sample ID, case ID, or requested assay...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(height: 16),

              // Table
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Diagnostic Specimen Pipeline', style: AppTypography.cardTitle),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No diagnostic samples matching query.')),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 22,
                          horizontalMargin: 12,
                          columns: const [
                            DataColumn(label: Text('Sample ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Case ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Specimen Type', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Requested Assay', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Priority', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Destination Lab', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Requested At', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filtered.map((t) {
                            final reqStr = DateFormat('dd MMM, HH:mm').format(t.requestedAt);
                            return DataRow(
                              cells: [
                                DataCell(Text(t.sampleId, style: const TextStyle(fontWeight: FontWeight.w700))),
                                DataCell(Text(t.caseId.toUpperCase())),
                                DataCell(Text(t.sampleType)),
                                DataCell(Text(t.testRequested, style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(StatusBadge.fromStatus(t.priority.toUpperCase())),
                                DataCell(Text(t.destinationLab ?? 'Central Lab, Pune')),
                                DataCell(StatusBadge.fromStatus(t.status.name.toUpperCase())),
                                DataCell(Text(reqStr, style: const TextStyle(fontSize: 12))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
