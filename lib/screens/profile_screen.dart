import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_authService.currentUser != null) {
      UserModel? user = await _authService.getUserData(_authService.currentUser!.uid);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Error al cargar perfil'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile Header
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Column(
                            children: [
                              // Avatar
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _user!.getInitials(),
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Name
                              Text(
                                _user!.name,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Email
                              Text(
                                _user!.email,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Stats
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatItem(
                              number: _user!.postsCount.toString(),
                              label: 'Total',
                            ),
                            _StatItem(
                              number: _user!.activePostsCount.toString(),
                              label: 'Activos',
                            ),
                            _StatItem(
                              number: _user!.resolvedPostsCount.toString(),
                              label: 'Resueltos',
                            ),
                          ],
                        ),
                      ),

                      // Actions
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _ProfileButton(
                              icon: Icons.logout,
                              label: 'Cerrar sesión',
                              onTap: _logout,
                              isDanger: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String number;
  final String label;

  const _StatItem({
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppTheme.primaryGradient.createShader(bounds),
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _ProfileButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: isDanger
            ? const LinearGradient(
                colors: [Color(0xFFFCA5A5), Color(0xFFEF4444)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isDanger ? AppTheme.errorColor : AppTheme.primaryColor)
                .withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

