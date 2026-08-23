import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class PdfSaver {
  /// Prompts file picker / downloads directory to save PDF across macOS, Windows, & Android
  static Future<void> savePdf({
    required BuildContext context,
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    try {
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'Save PDF Document',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (outputFile != null && outputFile.isNotEmpty) {
          final file = File(outputFile);
          await file.writeAsBytes(pdfBytes);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('PDF saved successfully to: $outputFile')),
            );
          }
        } else {
          // If save dialog canceled or unavailable, save directly to Downloads
          final downloadsDir = await getDownloadsDirectory();
          if (downloadsDir != null) {
            final savePath = "${downloadsDir.path}/$fileName";
            final file = File(savePath);
            await file.writeAsBytes(pdfBytes);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('PDF saved to Downloads folder: $savePath')),
              );
            }
          }
        }
      } else if (Platform.isAndroid || Platform.isIOS) {
        Directory? downloadsDir;
        if (Platform.isAndroid) {
          downloadsDir = Directory('/storage/emulated/0/Download');
          if (!downloadsDir.existsSync()) {
            downloadsDir = await getExternalStorageDirectory();
          }
        } else {
          downloadsDir = await getApplicationDocumentsDirectory();
        }

        if (downloadsDir != null) {
          final savePath = "${downloadsDir.path}/$fileName";
          final file = File(savePath);
          await file.writeAsBytes(pdfBytes);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('PDF saved to Downloads: $fileName')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save PDF: $e')),
        );
      }
    }
  }
}
