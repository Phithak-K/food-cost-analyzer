import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_role_provider.dart';
import '../theme/app_theme.dart';
import 'capsule_toast.dart';
import 'manager_pin_dialog.dart';

class RoleSwitcherPill extends ConsumerWidget {
  const RoleSwitcherPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRole = ref.watch(userRoleProvider);

    return PopupMenuButton<UserRole>(
      key: const Key('role_switcher_button'),
      tooltip: 'สลับบทบาทจำลอง (Demo Persona Switcher)',
      offset: const Offset(0, 48),
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 340),
      color: const Color(0xFF161B26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border, width: 1),
      ),
      elevation: 12,
      onSelected: (selectedRole) async {
        if (selectedRole == currentRole) return;

        // If switching to manager from another role, require manager PIN verification
        if (selectedRole == UserRole.manager && currentRole != UserRole.manager) {
          final isAuthorized = await showManagerPinDialog(
            context,
            ref: ref,
            targetTitle: 'ผู้จัดการ (Manager)',
          );
          if (!isAuthorized) return;
          if (!context.mounted) return;
          final location = GoRouterState.of(context).matchedLocation;
          if (!UserRole.manager.canAccessRoute(location)) {
            context.go(UserRole.manager.defaultRoute);
          }
          return;
        }

        // 1. Update Riverpod State
        ref.read(userRoleProvider.notifier).setRole(selectedRole);

        // 2. Check route permission and auto-redirect if necessary
        final location = GoRouterState.of(context).matchedLocation;
        if (!selectedRole.canAccessRoute(location)) {
          context.go(selectedRole.defaultRoute);
        }

        // 3. User feedback toast
        CapsuleToast.showInfo(
          context,
          'สลับบทบาทเป็น "${selectedRole.label}" เรียบร้อยแล้ว',
          title: 'เปลี่ยนมุมมองผู้ใช้งาน',
        );
      },
      itemBuilder: (context) {
        return UserRole.values.map((role) {
          final isSelected = role == currentRole;
          return PopupMenuItem<UserRole>(
            value: role,
            key: Key('role_${role.name}'),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: role.color.withValues(alpha: isSelected ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: role.color.withValues(alpha: isSelected ? 0.6 : 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    role.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              role.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? Colors.white : AppTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: role.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: role.color,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_rounded, color: role.color, size: 18),
              ],
            ),
          );
        }).toList();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: currentRole.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: currentRole.color.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: currentRole.color.withValues(alpha: 0.18),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentRole.emoji,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(width: 8),
            Text(
              currentRole.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: currentRole.color,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: currentRole.color,
            ),
          ],
        ),
      ),
    );
  }
}
