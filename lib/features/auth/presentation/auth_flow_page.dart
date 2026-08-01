import 'package:flutter/material.dart';

class AuthFlowPage extends StatelessWidget {
  const AuthFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saúde Financeira Familiar'),
      ),
      body: const Center(
        child: Text(
          'Sprint 2 - Autenticação',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}