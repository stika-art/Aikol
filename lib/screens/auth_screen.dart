import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _canCheckBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canCheck = await BiometricService.canAuthenticate();
    final isEnabled = await BiometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _canCheckBiometric = canCheck && isEnabled;
      });
      if (_canCheckBiometric) {
        _handleBiometricAuth();
      }
    }
  }

  Future<void> _handleBiometricAuth() async {
    setState(() => _isLoading = true);
    final success = await BiometricService.tryBiometricLogin();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Биометрический вход не удался')),
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите email и пароль')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await SupabaseService.signIn(_emailController.text, _passwordController.text);
      // Если вход успешен, сохраняем для биометрии
      await BiometricService.saveCredentials(_emailController.text, _passwordController.text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка входа: проверьте данные')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Aikol',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: -2),
              ),
              const SizedBox(height: 12),
              const Text(
                'Вход в систему',
                style: TextStyle(color: AppTheme.textDim, fontSize: 16),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(hintText: 'Пароль'),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleAuth,
                    child: const Text('Войти'),
                  ),
                ),
                if (_canCheckBiometric) ...[
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _handleBiometricAuth,
                    icon: const Icon(Icons.fingerprint, size: 28),
                    label: const Text('Войти через отпечаток пальца'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

