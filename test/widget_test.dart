import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('basic smoke widget test', (WidgetTester tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                const Text('BookHub test screen'),
                Text('tapped: $tapped'),
                ElevatedButton(
                  onPressed: () => setState(() => tapped = true),
                  child: const Text('Tap'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('BookHub test screen'), findsOneWidget);
    expect(find.text('tapped: false'), findsOneWidget);

    await tester.tap(find.text('Tap'));
    await tester.pump();

    expect(find.text('tapped: true'), findsOneWidget);
  });
}
