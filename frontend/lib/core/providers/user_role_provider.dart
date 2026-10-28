import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole {
  manager,
  cashier,
  kitchen;

  String get label {
    switch (this) {
      case UserRole.manager:
        return 'ผู้จัดการ (Manager)';
      case UserRole.cashier:
        return 'แคชเชียร์ (Cashier)';
      case UserRole.kitchen:
        return 'ครัว (Kitchen)';
    }
  }

  String get shortLabel {
    switch (this) {
      case UserRole.manager:
        return 'Manager';
      case UserRole.cashier:
        return 'Cashier';
      case UserRole.kitchen:
        return 'Kitchen';
    }
  }

  String get emoji {
    switch (this) {
      case UserRole.manager:
        return '👔';
      case UserRole.cashier:
        return '🧾';
      case UserRole.kitchen:
        return '👨‍🍳';
    }
  }

  String get description {
    switch (this) {
      case UserRole.manager:
        return 'เข้าถึงครบทุกระบบ: แดชบอร์ดเมทริกซ์, คลังวัตถุดิบ, สูตร, Simulation, POS, KDS';
      case UserRole.cashier:
        return 'หน้าร้านรับออเดอร์ (POS), เช็กสต็อกหน้าร้าน และดูประวัติบิล';
      case UserRole.kitchen:
        return 'จอแสดงคิวอาหาร (KDS) และคู่มือสัดส่วนตักปรุง (Portion Guide)';
    }
  }

  String get defaultRoute {
    switch (this) {
      case UserRole.manager:
        return '/dashboard';
      case UserRole.cashier:
        return '/pos';
      case UserRole.kitchen:
        return '/kds';
    }
  }

  Color get color {
    switch (this) {
      case UserRole.manager:
        return const Color(0xFF10B981); // Emerald Green
      case UserRole.cashier:
        return const Color(0xFF38BDF8); // Sky Blue
      case UserRole.kitchen:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  String get pinCode {
    switch (this) {
      case UserRole.manager:
        return '1234';
      case UserRole.cashier:
        return '2222';
      case UserRole.kitchen:
        return '3333';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.manager:
        return Icons.admin_panel_settings_rounded;
      case UserRole.cashier:
        return Icons.point_of_sale_rounded;
      case UserRole.kitchen:
        return Icons.restaurant_rounded;
    }
  }

  bool canAccessRoute(String route) {
    if (this == UserRole.manager) return true;
    if (this == UserRole.cashier) {
      return route.startsWith('/pos') || route.startsWith('/orders');
    }
    if (this == UserRole.kitchen) {
      return route.startsWith('/kds');
    }
    return false;
  }
}

class UserRoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() {
    return UserRole.manager;
  }

  void setRole(UserRole role) {
    state = role;
  }
}

final userRoleProvider = NotifierProvider<UserRoleNotifier, UserRole>(
  UserRoleNotifier.new,
);

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() {
    // False on initial app launch to show Role Selection Portal
    return false;
  }

  void login() {
    state = true;
  }

  void logout() {
    state = false;
  }
}

final authProvider = NotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);
