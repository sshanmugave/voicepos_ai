import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voicepos_ai/main.dart';
import 'package:voicepos_ai/services/app_state.dart';

void main() {
  testWidgets('shows splash while app state is not initialized', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(appState: AppState()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
