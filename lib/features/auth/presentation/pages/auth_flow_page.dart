import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthFlowPage extends StatelessWidget {
  const AuthFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return snapshot.data == null
            ? const LoginPage()
            : const DashboardPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) _show(_messageFor(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _recoverPassword() async {
    final email = _email.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _show('Digite um e-mail válido no campo acima.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) _show('Instruções enviadas para $email.');
    } on FirebaseAuthException catch (error) {
      if (mounted) _show(_messageFor(error));
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 44,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Saúde Financeira Familiar',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Organize sua vida financeira com segurança.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Informe seu e-mail.';
                        if (!text.contains('@')) {
                          return 'Informe um e-mail válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _hidePassword
                              ? 'Mostrar senha'
                              : 'Ocultar senha',
                          onPressed: () {
                            setState(() => _hidePassword = !_hidePassword);
                          },
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => (value ?? '').length < 6
                          ? 'A senha deve ter pelo menos 6 caracteres.'
                          : null,
                      onFieldSubmitted: (_) => _login(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading ? null : _recoverPassword,
                        child: const Text('Esqueci minha senha'),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _loading ? null : _login,
                      icon: _loading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Entrar'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loading
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const RegisterPage(),
                              ),
                            ),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Criar conta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _email.text.trim(),
            password: _password.text,
          );

      final user = credential.user!;
      final name = _name.text.trim();

      await user.updateDisplayName(name);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': user.emailVerified,
      });

      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_messageFor(error))));
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.message ?? 'Não foi possível salvar seu perfil.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value ?? '').trim().length < 3
                          ? 'Informe seu nome completo.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty || !text.contains('@')) {
                          return 'Informe um e-mail válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => _hidePassword = !_hidePassword);
                          },
                          icon: Icon(
                            _hidePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => (value ?? '').length < 6
                          ? 'Use pelo menos 6 caracteres.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmation,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar senha',
                        prefixIcon: Icon(Icons.lock_reset_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value != _password.text
                          ? 'As senhas não são iguais.'
                          : null,
                      onFieldSubmitted: (_) => _register(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _loading ? null : _register,
                      icon: _loading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_add_alt_1),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text('Cadastrar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName?.trim();
    final firstName = displayName == null || displayName.isEmpty
        ? null
        : displayName.split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saúde Financeira Familiar'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: FirebaseAuth.instance.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            firstName == null ? 'Bem-vindo(a)!' : 'Olá, $firstName!',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(user?.email ?? ''),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Autenticação concluída',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Login, cadastro, recuperação de senha, sessão persistente e logout estão funcionando.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _messageFor(FirebaseAuthException error) {
  switch (error.code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'E-mail ou senha incorretos.';
    case 'email-already-in-use':
      return 'Este e-mail já possui uma conta.';
    case 'invalid-email':
      return 'O endereço de e-mail é inválido.';
    case 'weak-password':
      return 'Escolha uma senha mais forte.';
    case 'too-many-requests':
      return 'Muitas tentativas. Aguarde alguns minutos.';
    case 'network-request-failed':
      return 'Verifique sua conexão com a internet.';
    case 'operation-not-allowed':
      return 'Ative E-mail/Senha no Firebase Authentication.';
    default:
      return error.message ?? 'Não foi possível concluir a operação.';
  }
}
