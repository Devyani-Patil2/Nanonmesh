// This is a basic Flutter widget test placeholder.
// Proper tests to be added as features are completed.

import 'package:flutter_test/flutter_test.dart';
import 'package:nanonmesh/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const NanonMeshApp());
    // Verify splash screen shows
    expect(find.text('NanonMesh'), findsOneWidget);
  });
}
