import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/widgets/emoji_picker_sheet.dart';

void main() {
  group('EmojiPickerSheet Tests', () {
    testWidgets('renders category chips and emoji grid correctly', (tester) async {
      String? selectedEmoji;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedEmoji = await EmojiPickerSheet.show(
                    context,
                    initialEmoji: '💵',
                  );
                },
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      // Tap button to open sheet
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Emoji / Ikon'), findsOneWidget);
      expect(find.text('Keuangan'), findsOneWidget);
      expect(find.text('Makanan'), findsOneWidget);

      // Tap an emoji in the grid
      final emojiWidget = find.text('💵');
      expect(emojiWidget, findsOneWidget);

      await tester.tap(emojiWidget);
      await tester.pumpAndSettle();

      expect(selectedEmoji, '💵');
    });

    testWidgets('switches categories when tapping category chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => EmojiPickerSheet.show(context),
                child: const Text('Open Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Tap 'Makanan' chip
      await tester.tap(find.text('Makanan'));
      await tester.pumpAndSettle();

      expect(find.text('🍔'), findsOneWidget);
    });
  });
}
