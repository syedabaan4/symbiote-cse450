import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../tasks/pages/tasks_page.dart';
import '../../moods/pages/mood_tracker_page.dart';
import '../../settings/pages/settings_page.dart';
import '../../export/pages/export_page.dart';
import '../../export/cubit/export_cubit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 40,
                      width: 40,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
      
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Spacer(flex: 4),
      
                    _buildDrawerItem(
                      context,
                      'Home',
                      isSelected: true,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 4),
                    _buildDrawerItem(
                      context,
                      'Tasks',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TasksPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    _buildDrawerItem(
                      context,
                      'Mood',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MoodTrackerPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    _buildDrawerItem(
                      context,
                      'Export',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (context) => ExportCubit(),
                              child: const ExportPage(),
                            ),
                          ),
                        );
                      },
                    ),
      
                    _buildDrawerItem(
                      context,
                      'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                    ),
      
                    const Spacer(flex: 1),
                  ],
                ),
              ),
            ),
      
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is Authenticated) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withValues(
                            alpha: 0.2,
                          ),
                          backgroundImage: state.user.photoURL != null
                              ? NetworkImage(state.user.photoURL!)
                              : null,
                          child: state.user.photoURL == null
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.user.displayName ??
                                state.user.email?.split('@').first ??
                                'User',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black.withValues(alpha: 0.9),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title, {
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.black.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: GoogleFonts.pixelifySans(
            fontSize: 18,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: Colors.black.withValues(alpha: (isSelected ? 1.0 : 0.9)),
          ),
        ),
      ),
    );
  }
}
