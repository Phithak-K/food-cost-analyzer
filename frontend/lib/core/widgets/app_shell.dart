import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      body: Row(
        children: [
          // Desktop / Large Screen Sidebar
          if (isDesktop) _buildSidebar(context, location),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                _buildTopAppBar(context, isDesktop),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
      // Drawer on smaller screens
      drawer: isDesktop ? null : Drawer(child: _buildSidebar(context, location, isDrawer: true)),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _getIndexFromLocation(location),
              onDestinationSelected: (idx) => _onNavigate(context, idx),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'แดชบอร์ด',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book_rounded),
                  label: 'สูตรอาหาร',
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
            ),
    );
  }

  Widget _buildSidebar(BuildContext context, String location, {bool isDrawer = false}) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MenuEng Pro',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

          // Navigation Links
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'MAIN MENU',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 8),

          _SidebarItem(
            icon: Icons.dashboard_rounded,
            title: 'ภาพรวม & Matrix',
            isSelected: location.startsWith('/dashboard'),
            onTap: () {
              if (isDrawer) Navigator.pop(context);
              context.go('/dashboard');
            },
          ),
          _SidebarItem(
            icon: Icons.menu_book_rounded,
            title: 'สูตรอาหาร (Recipes)',
            isSelected: location == '/recipes',
            onTap: () {
              if (isDrawer) Navigator.pop(context);
              context.go('/recipes');
            },
          ),
          _SidebarItem(
            icon: Icons.add_circle_outline_rounded,
            title: 'สร้างสูตร (Recipe Builder)',
            isSelected: location.startsWith('/recipes/builder'),
            onTap: () {
              if (isDrawer) Navigator.pop(context);
              context.go('/recipes/builder');
            },
          ),
          _SidebarItem(
            icon: Icons.inventory_2_rounded,
            title: 'วัตถุดิบ & คลัง (Ingredients)',
            isSelected: location.startsWith('/ingredients'),
            onTap: () {
              if (isDrawer) Navigator.pop(context);
              context.go('/ingredients');
            },
          ),
          _SidebarItem(
            icon: Icons.tune_rounded,
            title: 'จำลองต้นทุน (What-If)',
            isSelected: location.startsWith('/simulation'),
            onTap: () {
              if (isDrawer) Navigator.pop(context);
              context.go('/simulation');
            },
          ),

          const Spacer(),

          // Restaurant info footer
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  child: const Icon(Icons.storefront_rounded, size: 18, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grand Bistro & Grill',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'สาขาหลัก (Main Kitchen)',
                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context, bool isDesktop) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          if (!isDesktop) ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            const SizedBox(width: 8),
          ],
          // Search quick bar
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              height: 38,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'ค้นหาเมนู, วัตถุดิบ, หรือสูตรอาหาร...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  fillColor: AppTheme.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          // System Status & User Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Web/Desktop Online',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.success),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppTheme.textSecondary),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primary,
            child: Text(
              'C',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  int _getIndexFromLocation(String location) {
    if (location.startsWith('/recipes')) return 1;
    if (location.startsWith('/ingredients')) return 2;
    if (location.startsWith('/simulation')) return 3;
    return 0;
  }

  void _onNavigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/recipes');
        break;
      case 2:
        context.go('/ingredients');
        break;
      case 3:
        context.go('/simulation');
        break;
    }
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          dense: true,
          leading: Icon(
            icon,
            size: 20,
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
