import 'package:flutter/material.dart';
import '../config/colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppNavigationBar extends StatelessWidget {
  final String currentScreen;
  final Function(String) onScreenChanged;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const AppNavigationBar({
    super.key,
    required this.currentScreen,
    required this.onScreenChanged,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              icon: PhosphorIcons.house(PhosphorIconsStyle.fill),
              label: 'Home',
              screenId: 'roomSelection',
              isActive: currentScreen == 'roomSelection',
            ),
            _buildNavItem(
              context,
              icon: PhosphorIcons.ticket(PhosphorIconsStyle.fill),
              label: 'Issues',
              screenId: 'activeIssues',
              isActive: currentScreen == 'activeIssues',
            ),
            _buildNavItem(
              context,
              icon: PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill),
              label: 'History',
              screenId: 'history',
              isActive: currentScreen == 'history',
            ),
            _buildNavItem(
              context,
              icon: PhosphorIcons.users(PhosphorIconsStyle.fill),
              label: 'Team',
              screenId: 'team',
              isActive: currentScreen == 'team',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String screenId,
    required bool isActive,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => onScreenChanged(screenId),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
