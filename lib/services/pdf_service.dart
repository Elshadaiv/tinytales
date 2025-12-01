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
    final babyDoc = await FirebaseFirestore.instance
        .collection('baby_profiles')
        .doc(babyId)
        .get();

    final babyData = babyDoc.data() ?? {};

    final String dob = (babyData['dob'] ?? '') as String;
    final String gender = (babyData['gender'] ?? '') as String;
    final String weight = (babyData['weight'] ?? '') as String;
    final String height = (babyData['height'] ?? '') as String;
    final String hospital = (babyData['hospital'] ?? '') as String;

    final immunisationQuery = await FirebaseFirestore.instance
        .collection('baby_profiles')
        .doc(babyId)
        .collection('immunisations')
        .get();

    final List<Map<String, String>> immunisations = immunisationQuery.docs.map((doc)
    {
      final data = doc.data();
      final name = (data['name'] ?? 'Unknown').toString();
      final datesList = (data['dates'] as List?) ?? [];
      final dates = datesList.map((d) => d.toString()).join(', ');
      return
        {
          'name': name,
          'dates': dates.isEmpty ? '-' : dates,
        };
    }).toList();

    final Map<String, List<String>> vaccineSchedule =
    {
      'At 2 months': ['6-in-1', 'PCV ', 'Rotavirus', 'MenB'],
      'At 4 months': ['6-in-1', 'PCV ', 'Rotavirus'],
      'At 6 months': ['6-in-1', 'MenB'],
      'At 12 months': ['MMR', 'MenB', 'PCV '],
      'At 13 months': ['Hib/MenC'],
    };

    final pdf = pw.Document();

    final titleStyle = pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold);
    final sectionTitleStyle = pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold);
    final labelStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);
    final valueStyle = const pw.TextStyle(fontSize: 12);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context)
        {
          return
            [
              pw.Text("$babyName's Immunisation Passport", style: titleStyle),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey700),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Child's details", style: sectionTitleStyle),
                    pw.SizedBox(height: 8),
                    _detailRow("Child's name", babyName, labelStyle, valueStyle),
                    _detailRow("Date of birth", dob, labelStyle, valueStyle),
                    _detailRow("Gender", gender, labelStyle, valueStyle),
                    _detailRow("Birth weight", weight, labelStyle, valueStyle),
                    _detailRow("Birth height", height, labelStyle, valueStyle),
                    _detailRow("Hospital", hospital, labelStyle, valueStyle),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text("Immunisation Schedule", style: sectionTitleStyle),
              pw.SizedBox(height: 8),
              ...vaccineSchedule.entries.map((entry) {
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey500),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: double.infinity,
                        color: PdfColors.grey300,
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: pw.Text(entry.key,
                            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: entry.value
                              .map((v) => pw.Bullet(text: v, style: const pw.TextStyle(fontSize: 12)))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              pw.SizedBox(height: 20),

              pw.Text("Recorded Immunisations", style: sectionTitleStyle),
              pw.SizedBox(height: 8),

              if (immunisations.isEmpty)
                pw.Text("No immunisation records have been saved yet.",
                    style: pw.TextStyle(fontSize: 12))
              else
                pw.Table.fromTextArray(
                  headers: ['Vaccine name', 'Dates given'],
                  data: immunisations.map((v) => [v['name']!, v['dates']!]).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                  cellStyle: const pw.TextStyle(fontSize: 11),
                  cellAlignment: pw.Alignment.centerLeft,
                  border: pw.TableBorder.all(color: PdfColors.grey600),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                ),
            ];
        },
      ),
    );
    final outputDir = await getApplicationDocumentsDirectory();
    final safeName = babyName.replaceAll(' ', '_').replaceAll('/', '_').toLowerCase();
    final file = File("${outputDir.path}/${safeName}_immunisation_passport.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _detailRow(
      String label,
      String value,
      pw.TextStyle labelStyle,
      pw.TextStyle valueStyle,
      )
  {
    final displayValue = value.isEmpty ? '-' : value;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children:
        [
          pw.SizedBox(width: 120, child: pw.Text(label, style: labelStyle)),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.5),
                ),
              ),
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(displayValue, style: valueStyle),
            ),
          ),
        ],
      ),
    );
  }
}