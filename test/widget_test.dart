import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BizzFlow test básico', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('BizzFlow'),
        ),
      ),
    );

    expect(find.text('BizzFlow'), findsOneWidget);
  });
}
