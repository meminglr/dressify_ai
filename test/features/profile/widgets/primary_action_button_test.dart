import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dressifyai/features/profile/widgets/primary_action_button.dart';

void main() {
  group('PrimaryActionButton Widget Tests', () {
    bool wasPressed = false;

    setUp(() {
      wasPressed = false;
    });

    testWidgets('should display label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryActionButton(
              label: 'Yeni Üret',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Yeni Üret'), findsOneWidget);
    });

    testWidgets('should display icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryActionButton(
              label: 'Yeni Üret',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryActionButton(
              label: 'Yeni Üret',
              icon: Icons.add,
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(wasPressed, true);
    });

    testWidgets('should have correct background color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryActionButton(
              label: 'Yeni Üret',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      final elevatedButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      final buttonStyle = elevatedButton.style;
      final backgroundColor = buttonStyle?.backgroundColor?.resolve({});

      expect(backgroundColor, const Color(0xFF742FE5));
    });

    testWidgets('should have correct text color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryActionButton(
              label: 'Yeni Üret',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      final elevatedButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      final buttonStyle = elevatedButton.style;
      final foregroundColor = buttonStyle?.foregroundColor?.resolve({});

      expect(foregroundColor, const Color(0xFFFFFFFF));
    });

    testWidgets('should have pill shape (circular border radius)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryActionButton(
              label: 'Yeni Üret',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      final elevatedButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      final buttonStyle = elevatedButton.style;
      final shape = buttonStyle?.shape?.resolve({}) as RoundedRectangleBorder?;

      expect(shape?.borderRadius, BorderRadius.circular(9999));
    });

    testWidgets('should have correct padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryActionButton(
              label: 'Yeni Üret',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      final elevatedButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      final buttonStyle = elevatedButton.style;
      final padding = buttonStyle?.padding?.resolve({});

      expect(
        padding,
        const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      );
    });

    testWidgets('should have BackdropFilter for blur effect', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryActionButton(
              label: 'Yeni Üret',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('should have shadow decoration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryActionButton(
              label: 'Yeni Üret',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Find the Container with BoxDecoration
      final containerFinder = find.ancestor(
        of: find.byType(ClipRRect),
        matching: find.byType(Container),
      );

      expect(containerFinder, findsOneWidget);

      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration?;

      expect(decoration?.boxShadow, isNotNull);
      expect(decoration?.boxShadow?.length, 2);
    });

    testWidgets('should have icon before text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryActionButton(
              label: 'Yeni Üret',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Find the Row widget inside the button
      final rowFinder = find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.byType(Row),
      );

      expect(rowFinder, findsOneWidget);

      final row = tester.widget<Row>(rowFinder);
      expect(row.children.length, 3); // Icon, SizedBox, Text

      // First child should be Icon
      expect(row.children[0], isA<Icon>());
      // Second child should be SizedBox (spacing)
      expect(row.children[1], isA<SizedBox>());
      // Third child should be Text
      expect(row.children[2], isA<Text>());
    });
  });
}
