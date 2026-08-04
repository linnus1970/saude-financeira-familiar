import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saude_financeira_familiar/features/auth/presentation/pages/auth_flow_page.dart';

void main() {
  test('validação rejeita e-mail vazio e inválido', () {
    expect(validateResetEmail(''), isNotNull);
    expect(validateResetEmail('email-invalido'), isNotNull);
    expect(validateResetEmail('pessoa@exemplo.com'), isNull);
  });

  testWidgets('envia recuperação com e-mail válido em largura mobile', (
    tester,
  ) async {
    String? sentEmail;
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PasswordResetDialog(
            sendResetEmail: (email) async => sentEmail = email,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), ' pessoa@exemplo.com ');
    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(sentEmail, 'pessoa@exemplo.com');
    expect(tester.takeException(), isNull);
  });

  testWidgets('não revela quando Firebase informa usuário inexistente', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PasswordResetDialog(
            initialEmail: 'ausente@exemplo.com',
            sendResetEmail: (_) =>
                throw FirebaseAuthException(code: 'user-not-found'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Enviar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('não possui'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
