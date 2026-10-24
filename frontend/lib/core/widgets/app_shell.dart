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
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                  child: const Icon(Icons.storefront_rounded, size: 18, color: AppTheme.primaryNeon),
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
        color: AppTheme.backgroundElevated,
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
              height: 40,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'ค้นหาเมนู, วัตถุดิบ, หรือสูตรอาหาร...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
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
          ),
          const Spacer(),
          // System Status & User Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
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
                ),
                const SizedBox(width: 8),
                const Text(
                  'Web/Desktop Online',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryNeon),
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
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 17,
              backgroundColor: AppTheme.primary,
              child: Text(
                'C',
                style: TextStyle(color: Color(0xFF0B0F19), fontSize: 13, fontWeight: FontWeight.w800),
              ),
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
                color: isSelected ? AppTheme.primaryNeon : AppTheme.textSecondary,
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
              trailing: isSelected
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
                  : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ),
    );
  }
}
