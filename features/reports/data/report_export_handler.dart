import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/core/platform/file_download_service.dart';
import 'package:flock_sense/features/reports/data/csv_generator.dart';
import 'package:flock_sense/features/reports/data/excel_generator.dart';
import 'package:flock_sense/features/reports/data/pdf_generator.dart';
import 'package:flock_sense/features/reports/data/report_history_service.dart';
import 'package:flock_sense/features/reports/domain/report_data.dart';
import 'package:flock_sense/features/reports/domain/report_types.dart';

class ReportExportHandler {
  static Future<Uint8List> generateBytes({
    required ReportData data,
    required ReportType reportType,
    required ExportFormat format,
  }) async {
    switch (format) {
      case ExportFormat.pdf:
        return PdfGenerator.generatePdfForReportType(
          data: data,
          reportType: reportType,
        );
      case ExportFormat.excel:
        return ExcelGenerator.generateExcelReport(
          data: data,
          reportType: reportType,
        );
      case ExportFormat.csv:
        return CsvGenerator.generateCsvReport(
          data: data,
          reportType: reportType,
        );
    }
  }

  static Future<void> downloadOrShareReport({
    required ReportData data,
    required ReportType reportType,
    required ExportFormat format,
  }) async {
    final bytes = await generateBytes(
      data: data,
      reportType: reportType,
      format: format,
    );

    final sanitizedTitle = reportType.title.replaceAll(' ', '_').toLowerCase();
    final filename =
        'flocksense_${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}${format.extension}';

    await FileDownloadService.downloadFile(
      bytes: bytes,
      fileName: filename,
      mimeType: _getMimeType(format),
    );

    final historyItem = ReportHistoryItem(
      id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
      reportType: reportType,
      reportTitle: reportType.title,
      farmName: data.farm.farmName,
      batchName: data.batch.batchName,
      format: format,
      generatedAt: DateTime.now(),
      fileSizeKb: (bytes.lengthInBytes / 1024.0),
      filePath: filename,
    );

    await ReportHistoryService.saveHistoryItem(historyItem);
  }

  static Future<void> shareReport({
    required ReportData data,
    required ReportType reportType,
    required ExportFormat format,
  }) async {
    await downloadOrShareReport(
      data: data,
      reportType: reportType,
      format: format,
    );
  }

  static String _getMimeType(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return 'application/pdf';
      case ExportFormat.excel:
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case ExportFormat.csv:
        return 'text/csv';
    }
  }
}
