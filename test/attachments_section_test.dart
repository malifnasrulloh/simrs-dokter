import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simrs_dokter/features/rekam_medis/views/widgets/attachments_section.dart';

void main() {
  group('stripAttachment Helper Tests', () {
    test('removes [Attachment: URL] tags from text', () {
      const input = 'Hasil foto thorax [Attachment: https://pacs.example.com/img1.jpg] normal';
      final output = stripAttachment(input);
      expect(output, 'Hasil foto thorax  normal');
    });

    test('returns untouched text if no attachment tags are present', () {
      const input = 'Catatan SOAP biasa tanpa lampiran';
      expect(stripAttachment(input), input);
    });

    test('handles multiple attachment tags', () {
      const input = 'Item 1 [Attachment: https://a.com/1.pdf] Item 2 [Attachment: https://b.com/2.png]';
      expect(stripAttachment(input), 'Item 1  Item 2');
    });
  });

  group('buildAttachmentsSection Widget Tests', () {
    testWidgets('renders nothing when text has no attachment tags', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: buildAttachmentsSection('Catatan tanpa lampiran'),
        ),
      ));

      expect(find.byType(InkWell), findsNothing);
      expect(find.text('Lampiran / Attachments:'), findsNothing);
    });

    testWidgets('renders attachment chip when valid tag is present', (tester) async {
      const text = 'Foto klinis [Attachment: https://rs.example.com/pacs/thorax.jpg]';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: buildAttachmentsSection(text),
        ),
      ));

      expect(find.text('Lampiran / Attachments:'), findsOneWidget);
      expect(find.text('thorax.jpg'), findsOneWidget);
      expect(find.byIcon(Icons.image_rounded), findsOneWidget);
    });

    testWidgets('renders PDF icon for .pdf attachment', (tester) async {
      const text = 'Hasil Lab [Attachment: https://rs.example.com/docs/lab_result.pdf]';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: buildAttachmentsSection(text),
        ),
      ));

      expect(find.text('lab_result.pdf'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);
    });
  });
}
