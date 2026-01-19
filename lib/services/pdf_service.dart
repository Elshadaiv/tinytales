import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:open_file/open_file.dart';
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
    // fetch baby profile details
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

    // fetch all recorded immunisations for this baby
    final immunisationQuery = await FirebaseFirestore.instance
        .collection('baby_profiles')
        .doc(babyId)
        .collection('immunisations')
        .get();

    // firestore data for pdf rendering
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

    // map normalised vaccine name to latest recorded date
    final Map<String, String> latestByKey =
    {
    };

    for (final item in immunisations)
    {
      final name = (item['name'] ?? '').toString();
      final dates = (item['dates'] ?? '').toString();

      // skip vaccines with no recorded dates
      if (dates.trim().isEmpty || dates.trim() == '-')
      {
        continue;
      }

      // use most recent date for schedule matching
      final parts = dates.split(',');
      latestByKey[_matchKey(name)] = parts.last.trim();
    }

    final Map<String, List<String>> vaccineSchedule =
    {
      'At 2 months': ['6-in-1', 'PCV', 'Rotavirus', 'MenB'],
      'At 4 months': ['6-in-1', 'PCV', 'Rotavirus'],
      'At 6 months': ['6-in-1', 'MenB'],
      'At 12 months': ['MMR', 'MenB', 'PCV'],
      'At 13 months': ['Hib/MenC', 'PCV'],
    };

    final pdf = pw.Document();

    final titleStyle = pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold);
    final sectionTitleStyle = pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold);
    final labelStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);
    final valueStyle = pw.TextStyle(fontSize: 12);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(24),
        build: (pw.Context context)
        {
          return
            [
              pw.Text("$babyName's Immunisation Passport", style: titleStyle),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Container(
                padding: pw.EdgeInsets.all(10),
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
              // immunisation schedule with status colouring
              pw.Text("Immunisation Schedule", style: sectionTitleStyle),
              pw.SizedBox(height: 8),

              ...vaccineSchedule.entries.map((entry)
              {
                final String sectionLabel = entry.key;
                final List<String> vaccines = entry.value;

                return pw.Container(
                  margin: pw.EdgeInsets.only(bottom: 10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey500),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: double.infinity,
                        color: PdfColors.grey300,
                        padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: pw.Text(
                          sectionLabel,
                          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Table(
                        border: pw.TableBorder(
                          horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                        ),
                        columnWidths: {
                          0: pw.FlexColumnWidth(2.2),
                          1: pw.FlexColumnWidth(1.3),
                        },
                        children: [
                          // table header
                          pw.TableRow(
                            decoration: pw.BoxDecoration(color: PdfColors.grey200),
                            children: [
                              pw.Padding(
                                padding: pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  "Vaccine",
                                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                              pw.Padding(
                                padding: pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  "Date given",
                                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          ...vaccines.map((vaccine)
                          {
                            // check if vaccine exists in recorded list
                            final String date = (latestByKey[_matchKey(vaccine)] ?? '').trim();
                            final bool done = date.isNotEmpty;

                            final PdfColor rowColor = done ? PdfColors.green100 : PdfColors.red100;
                            return pw.TableRow(
                              decoration: pw.BoxDecoration(color: rowColor),
                              children: [
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(8),
                                  child: pw.Text(
                                    vaccine,
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.bold,
                                      color: done ? PdfColors.green900 : PdfColors.red900,
                                    ),
                                  ),
                                ),
                                pw.Padding(
                                  padding: pw.EdgeInsets.all(8),
                                  child: pw.Text(
                                    done ? date : "Not recorded",
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      color: done ? PdfColors.green900 : PdfColors.red900,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),

              pw.SizedBox(height: 20),
              // raw immunisation history table
              pw.Text("Recorded Immunisations", style: sectionTitleStyle),
              pw.SizedBox(height: 8),

              if (immunisations.isEmpty)
                pw.Text(
                  "No immunisation records have been saved yet.",
                  style: pw.TextStyle(fontSize: 12),
                )
              else
                pw.Table.fromTextArray(
                  headers: ['Vaccine name', 'Dates given'],
                  data: immunisations
                      .map((v) => [v['name']!, v['dates']!])
                      .toList(),
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
    // save pdf locally with timestamp to avoid caching issues
    final outputDir = await getApplicationDocumentsDirectory();
    final safeName = babyName.replaceAll(' ', '_').replaceAll('/', '_').toLowerCase();
    final stamp = DateTime.now().millisecondsSinceEpoch;

    final file = File("${outputDir.path}/${safeName}_immunisation_passport_$stamp.pdf");
    await file.writeAsBytes(await pdf.save());

    // open pdf after generation
    await OpenFile.open(file.path);

    return file;
  }
  // normalise vaccine names so matching works reliably
  static String _matchKey(String input)
  {
    var s = input.toLowerCase().trim();
    s = s.replaceAll('pvc', 'pcv');
    s = s.replaceAll('vaccine', '');
    s = s.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return s;
  }

  // reusable layout for baby detail rows
  static pw.Widget _detailRow(
      String label,
      String value,
      pw.TextStyle labelStyle,
      pw.TextStyle valueStyle,
      )
  {
    final displayValue = value.isEmpty ? '-' : value;
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children:
        [
          pw.SizedBox(width: 120, child: pw.Text(label, style: labelStyle)),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey600, width: 0.5),
                ),
              ),
              padding: pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(displayValue, style: valueStyle),
            ),
          ),
        ],
      ),
    );
  }
}