import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/translation_provider.dart';
import '../translator/translator_screen.dart';
import '../contacts/contacts_screen.dart';
import '../history/history_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    TranslatorScreen(),
    ContactsScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20, offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.translate_rounded, Icons.translate_rounded, 'Translate'),
                _navItem(1, Icons.people_outline_rounded, Icons.people_rounded, 'Contacts'),
                _navItem(2, Icons.history_rounded, Icons.history_rounded, 'History'),
                _navItem(3, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, IconData activeIcon, String label) {
    final isActive = _selectedIndex == idx;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primary : AppColors.textHint,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
