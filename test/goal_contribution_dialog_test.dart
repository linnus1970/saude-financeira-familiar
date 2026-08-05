import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saude_financeira_familiar/features/finance/presentation/pages/financial_dashboard_page.dart';

void main() {
  testWidgets('confirma aporte sem erro durante o fechamento do diálogo', (
    tester,
  ) async {
    double? contribution;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                contribution = await showDialog<double>(
                  context: context,
                  builder: (_) => const GoalContributionDialog(
                    remainingAmount: 750,
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '250,50');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(contribution, 250.50);
    expect(find.byType(GoalContributionDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
