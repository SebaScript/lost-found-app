import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;

        return Scaffold(
          backgroundColor: AppTheme.bgSecondary,
          appBar: AppBar(
            title: const Text('Perfil'),
          ),
          body: authProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : user == null
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
                                  color: user.photoUrl != null
                                      ? null
                                      : AppTheme.primaryColor,
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
                                child: user.photoUrl != null
                                    ? ClipOval(
                                        child: Image.network(
                                          user.photoUrl!,
                                          width: 110,
                                          height: 110,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Center(
                                              child: Text(
                                                user.getInitials(),
                                                style: const TextStyle(
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          user.getInitials(),
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
                                user.displayName,
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
                                user.email,
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
                              number: user.postsCount.toString(),
                              label: 'Total',
                            ),
                            _StatItem(
                              number: user.activePostsCount.toString(),
                              label: 'Activos',
                            ),
                            _StatItem(
                              number: user.resolvedPostsCount.toString(),
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
                              icon: Icons.edit,
                              label: 'Editar perfil',
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const EditProfileScreen()),
                                );
                                // Reload user data after edit
                                authProvider.reloadUserData();
                              },
                              isDanger: false,
                            ),
                            const SizedBox(height: 12),
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
      },
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
        Text(
          number,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
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
        color: isDanger ? AppTheme.errorColor : AppTheme.primaryColor,
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

