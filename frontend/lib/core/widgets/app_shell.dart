import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/widgets/business_glossary_dialog.dart';
import '../providers/system_status_provider.dart';
import '../providers/user_role_provider.dart';
import '../services/kds_websocket_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'manager_pin_dialog.dart';
import 'role_switcher_pill.dart';

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep real-time KDS WebSocket listener active throughout the application
    ref.watch(kdsWebSocketProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final isDesktop = Responsive.isDesktop(context);
    final currentRole = ref.watch(userRoleProvider);

    // Auto-redirect if route is restricted for current role
    if (!currentRole.canAccessRoute(location)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(currentRole.defaultRoute);
        }
      });
    }

    return Scaffold(
      body: Row(
        children: [
          // Desktop / Large Screen Sidebar
          if (isDesktop) _buildSidebar(context, ref, location, currentRole),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                _buildTopAppBar(context, ref, isDesktop, currentRole),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
      // Drawer on smaller screens
      drawer: isDesktop
          ? null
          : Drawer(child: _buildSidebar(context, ref, location, currentRole, isDrawer: true)),
      bottomNavigationBar: isDesktop
          ? null
          : _buildBottomNavigationBar(context, location, currentRole),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    WidgetRef ref,
    String location,
    UserRole currentRole, {
    bool isDrawer = false,
  }) {
    final menuItems = _buildRoleFilteredMenuItems(
      context,
      ref,
      location,
      currentRole,
      isDrawer: isDrawer,
    );

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundElevated,
        border: Border(right: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Branding Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryNeon],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Color(0xFF0B0F19),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MenuEng Pro',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Food Cost & Matrix',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          const SizedBox(height: 12),

          // Role-Aware Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MAIN MENU',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: currentRole.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: currentRole.color.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    currentRole.shortLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: currentRole.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Navigation Links
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: menuItems,
              ),
            ),
          ),

          // User Persona Info Footer with Switch Role Action
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: currentRole.color.withValues(alpha: 0.25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: currentRole.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: currentRole.color.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        currentRole.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentRole.label,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            currentRole == UserRole.manager
                                ? 'สิทธิ์เต็ม (Full Access)'
                                : 'คลิกเมนู 🔒 เพื่อใส่รหัสประจำตำแหน่ง',
                            style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (isDrawer) Navigator.pop(context);
                      ref.read(authProvider.notifier).logout();
                      context.go('/role-select');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: currentRole.color,
                      side: BorderSide(color: currentRole.color.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text(
                      'สลับบทบาท / หน้าแรก',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  UserRole _getRequiredRoleForRoute(String route) {
    if (route.startsWith('/kds')) {
      return UserRole.kitchen;
    }
    if (route.startsWith('/pos') || route.startsWith('/orders')) {
      return UserRole.cashier;
    }
    return UserRole.manager;
  }

  List<Widget> _buildRoleFilteredMenuItems(
    BuildContext context,
    WidgetRef ref,
    String location,
    UserRole currentRole, {
    required bool isDrawer,
  }) {
    Widget buildItem({
      required Key key,
      required IconData icon,
      required String title,
      required String targetRoute,
      bool exactMatch = false,
    }) {
      final isAccessible = currentRole.canAccessRoute(targetRoute);
      final isSelected = exactMatch ? location == targetRoute : location.startsWith(targetRoute);

      return _SidebarItem(
        key: key,
        icon: icon,
        title: title,
        isSelected: isSelected,
        isLocked: !isAccessible,
        onTap: () async {
          if (isDrawer) Navigator.pop(context);
          if (isAccessible) {
            context.go(targetRoute);
          } else {
            // Require role PIN verification to enter locked section
            final targetRole = _getRequiredRoleForRoute(targetRoute);
            final ok = await showStaffPinDialog(
              context,
              targetRole: targetRole,
              ref: ref,
              targetTitle: title,
            );
            if (ok && context.mounted) {
              context.go(targetRoute);
            }
          }
        },
      );
    }

    return [
      buildItem(
        key: const Key('sidebar_dashboard'),
        icon: Icons.dashboard_rounded,
        title: 'ภาพรวม & Matrix',
        targetRoute: '/dashboard',
      ),
      buildItem(
        key: const Key('sidebar_pos'),
        icon: Icons.point_of_sale_rounded,
        title: 'รับออเดอร์ (Quick POS)',
        targetRoute: '/pos',
      ),
      buildItem(
        key: const Key('sidebar_kds'),
        icon: Icons.restaurant_rounded,
        title: 'จอคิวอาหาร (KDS)',
        targetRoute: '/kds',
      ),
      buildItem(
        key: const Key('sidebar_display'),
        icon: Icons.tv_rounded,
        title: 'จอใหญ่ & จุดเสิร์ฟ (TV Display)',
        targetRoute: '/display',
      ),
      buildItem(
        key: const Key('sidebar_orders'),
        icon: Icons.receipt_long_rounded,
        title: 'ประวัติการขาย',
        targetRoute: '/orders',
      ),
      buildItem(
        key: const Key('sidebar_recipes'),
        icon: Icons.menu_book_rounded,
        title: 'สูตรอาหาร (Recipes)',
        targetRoute: '/recipes',
        exactMatch: true,
      ),
      buildItem(
        key: const Key('sidebar_recipe_builder'),
        icon: Icons.add_circle_outline_rounded,
        title: 'สร้างสูตร (Recipe Builder)',
        targetRoute: '/recipes/builder',
      ),
      buildItem(
        key: const Key('sidebar_ingredients'),
        icon: Icons.inventory_2_rounded,
        title: 'วัตถุดิบ & คลัง (Ingredients)',
        targetRoute: '/ingredients',
      ),
      buildItem(
        key: const Key('sidebar_forecast'),
        icon: Icons.auto_graph_rounded,
        title: 'พยากรณ์ & ป้องกันของเสีย',
        targetRoute: '/forecast',
      ),
      buildItem(
        key: const Key('sidebar_simulation'),
        icon: Icons.tune_rounded,
        title: 'จำลองต้นทุน (What-If)',
        targetRoute: '/simulation',
      ),
      const SizedBox(height: 6),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14),
        child: Divider(color: AppTheme.border, height: 16),
      ),
      _SidebarItem(
        key: const Key('sidebar_glossary'),
        icon: Icons.menu_book_rounded,
        title: 'คู่มือคำศัพท์ธุรกิจ',
        isSelected: false,
        isLocked: false,
        onTap: () {
          if (isDrawer) Navigator.pop(context);
          showBusinessGlossaryDialog(context);
        },
      ),
    ];
  }

  Widget _buildTopAppBar(BuildContext context, WidgetRef ref, bool isDesktop, UserRole currentRole) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Search bar needs at least 950px to comfortably fit alongside badges & buttons
        final showSearch = width >= 950;
        final showFullOnlineBadge = width >= 1050;
        final showCompactOnlineBadge = width >= 600;
        final showGlossaryButton = width >= 720;
        final showNotifications = width >= 780;

        return Container(
          height: 64,
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 12),
          decoration: const BoxDecoration(
            color: AppTheme.backgroundElevated,
            border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
          ),
          child: Row(
            children: [
              if (!isDesktop) ...[
                Builder(
                  builder: (drawerContext) => IconButton(
                    icon: const Icon(Icons.menu_rounded),
                    onPressed: () => Scaffold.of(drawerContext).openDrawer(),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              if (showSearch)
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    height: 40,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: isDesktop ? 'ค้นหาเมนู, วัตถุดิบ, หรือสูตรอาหาร...' : 'ค้นหา...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                        fillColor: Colors.white.withValues(alpha: 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const Expanded(
                  child: Text(
                    'MenuEng Pro',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (isDesktop && showSearch) const Spacer() else const SizedBox(width: 8),

              // Persona / Role Switcher Pill Widget
              const RoleSwitcherPill(),
              if (width >= 600) const SizedBox(width: 8),

              // System Status & User Action (Live Dynamic Health Badge)
              if (showFullOnlineBadge) ...[
                const SystemStatusBadge(compact: false),
                const SizedBox(width: 8),
              ] else if (showCompactOnlineBadge) ...[
                const SystemStatusBadge(compact: true),
                const SizedBox(width: 8),
              ],
              if (showGlossaryButton)
                IconButton(
                  icon: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryNeon, size: 20),
                  tooltip: 'คู่มือคำศัพท์ธุรกิจ & เมทริกซ์ (เปิดดู / ดาวน์โหลด)',
                  onPressed: () => showBusinessGlossaryDialog(context),
                ),
              if (showNotifications)
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.textSecondary),
                  onPressed: () {},
                ),
              const SizedBox(width: 6),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: currentRole.color.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: currentRole.color,
                  child: Text(
                    currentRole.shortLabel.substring(0, 1),
                    style: const TextStyle(color: Color(0xFF0B0F19), fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 20, color: AppTheme.textMuted),
                tooltip: 'สลับบทบาท / กลับหน้าหลัก (Switch Role)',
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/role-select');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget? _buildBottomNavigationBar(BuildContext context, String location, UserRole currentRole) {
    if (currentRole == UserRole.cashier) {
      final selectedIdx = location.startsWith('/orders') ? 1 : 0;
      return NavigationBar(
        selectedIndex: selectedIdx,
        onDestinationSelected: (idx) {
          if (idx == 0) context.go('/pos');
          if (idx == 1) context.go('/orders');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale_rounded),
            label: 'รับออเดอร์',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'ประวัติการขาย',
          ),
        ],
      );
    }

    if (currentRole == UserRole.kitchen) {
      // Kitchen role primarily operates on the full-screen KDS ticket queue;
      // no bottom navigation tabs needed (prevents destinations.length >= 2 assert error)
      return null;
    }

    // Default: Manager
    return NavigationBar(
      selectedIndex: _getManagerIndexFromLocation(location),
      onDestinationSelected: (idx) => _onManagerNavigate(context, idx),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'แดชบอร์ด',
        ),
        NavigationDestination(
          icon: Icon(Icons.point_of_sale_outlined),
          selectedIcon: Icon(Icons.point_of_sale_rounded),
          label: 'POS ขาย',
        ),
        NavigationDestination(
          icon: Icon(Icons.restaurant_outlined),
          selectedIcon: Icon(Icons.restaurant_rounded),
          label: 'จอครัว',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2_rounded),
          label: 'วัตถุดิบ',
        ),
        NavigationDestination(
          icon: Icon(Icons.tune_outlined),
          selectedIcon: Icon(Icons.tune_rounded),
          label: 'จำลองต้นทุน',
        ),
      ],
    );
  }

  int _getManagerIndexFromLocation(String location) {
    if (location.startsWith('/pos')) return 1;
    if (location.startsWith('/kds')) return 2;
    if (location.startsWith('/ingredients')) return 3;
    if (location.startsWith('/simulation')) return 4;
    return 0;
  }

  void _onManagerNavigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/pos');
        break;
      case 2:
        context.go('/kds');
        break;
      case 3:
        context.go('/ingredients');
        break;
      case 4:
        context.go('/simulation');
        break;
    }
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback onTap;

  const _SidebarItem({
    super.key,
    required this.icon,
    required this.title,
    required this.isSelected,
    this.isLocked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppTheme.primary.withValues(alpha: 0.35) : Colors.transparent,
                width: 1,
              ),
            ),
            child: ListTile(
              onTap: onTap,
              dense: true,
              leading: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppTheme.primaryNeon
                    : (isLocked ? AppTheme.textMuted : AppTheme.textSecondary),
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isLocked ? AppTheme.textMuted : AppTheme.textSecondary),
                ),
              ),
              trailing: isLocked
                  ? const Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: AppTheme.textMuted,
                    )
                  : (isSelected
                      ? Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryNeon,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryNeon,
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        )
                      : null),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ),
    );
  }
}
