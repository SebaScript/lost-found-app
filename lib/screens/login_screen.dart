import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
                child: const Column(
                  children: [
                    Text(
                      'Lost & Found',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Encuentra lo que perdiste',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),
                      const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 28),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Correo electrónico',
                        hint: 'correo@ejemplo.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu correo';
                          }
                          if (!value.contains('@')) {
                            return 'Correo inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: _passwordController,
                        label: 'Contraseña',
                        hint: '••••••••',
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu contraseña';
                          }
                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implement forgot password
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Funcionalidad próximamente'),
                              ),
                            );
                          },
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Iniciar Sesión',
                        onPressed: _login,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '¿No tienes cuenta? ',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterScreen()),
                                );
                              },
                              child: const Text(
                                'Regístrate',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

