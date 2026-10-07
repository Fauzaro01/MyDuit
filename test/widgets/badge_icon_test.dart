import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myduit/widgets/badge_icon.dart';
import 'package:myduit/widgets/animated_flame_icon.dart';

void main() {
  testWidgets('BadgeIcon renders every variant, locked and unlocked, without throwing', (
    tester,
  ) async {
    for (final type in BadgeIconType.values) {
      for (final locked in [true, false]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(child: BadgeIcon(type: type, locked: locked, size: 40)),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('AnimatedFlameIcon renders and animates without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: AnimatedFlameIcon(size: 36, active: true))),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('AnimatedFlameIcon renders the inactive (grey, static) state without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: AnimatedFlameIcon(size: 16, active: false))),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
