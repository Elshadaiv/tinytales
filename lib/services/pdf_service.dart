import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;


class PDFservice
{
  static Future<File> generateImmunisationPDF(
  {
    required String babyId,
    required String babyName,
}) async
  {
    final PDF = pw.Document();

    final snapshot = await FirebaseFirestore.instance
    .collection('baby_profiles')
    .doc(babyId)
    .collection('immunisations')
    .get();

    final immunisations = snapshot.docs.map((doc)
        {
          final data = doc.data();
          return
              {
                'name': data ['name'] ?? 'Unknown',
                'dates': (data['dates'] as List?)?.join(', ') ?? '-',
              };

        }).toList();

    PDF.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) =>
            [
              pw.Header(
                level: 0,
                child: pw.Text(
                  "$babyName's Immunisation Passport",
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                ),
              ),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Vaccine Name', 'Dates Given'],
                  data: immunisations.map((v) => [v['name'], v['dates']]).toList(),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 12),
                  border: pw.TableBorder.all(color: PdfColors.grey700),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey600),
              ),
            ],
      ),
    );
    
    final outputDir = await getApplicationDocumentsDirectory();
    final file = File("${outputDir.path}/${babyName}_immunisation.pdf");
    await file.writeAsBytes(await PDF.save());
    return file;
  }
  
}