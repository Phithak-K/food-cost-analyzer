import 'package:flutter/material.dart';

/// Application-wide constants for styling, thresholds, and domain concepts.
class AppConstants {
  static const String appName = 'Menu Engineering & Food Costing';
  static const String appVersion = '1.0.0';

  // Benchmark Food Cost percentage targets for standard F&B
  static const double targetFoodCostMin = 28.0; // 28%
  static const double targetFoodCostMax = 35.0; // 35%

  // Breakpoints
  static const double desktopBreakpoint = 1100.0;
  static const double tabletBreakpoint = 768.0;

  // Spacing & Radius
  static const double defaultPadding = 24.0;
  static const double cardPadding = 20.0;
  static const double defaultRadius = 12.0;
}

/// Menu Engineering Quadrant based on Kasavana & Smith Matrix:
/// - Star: High Profitability, High Popularity
/// - Plowhorse (Workhorse): Low Profitability, High Popularity
/// - Puzzle: High Profitability, Low Popularity
/// - Dog: Low Profitability, Low Popularity
enum MenuQuadrant {
  star,
  plowhorse,
  puzzle,
  dog;

  String get displayName {
    switch (this) {
      case MenuQuadrant.star:
        return 'Star (ดาวเด่น)';
      case MenuQuadrant.plowhorse:
        return 'Plowhorse (ม้างาน)';
      case MenuQuadrant.puzzle:
        return 'Puzzle (ปริศนา)';
      case MenuQuadrant.dog:
        return 'Dog (ตัดทิ้ง/ปรับปรุง)';
    }
  }

  String get shortName {
    switch (this) {
      case MenuQuadrant.star:
        return 'Star';
      case MenuQuadrant.plowhorse:
        return 'Plowhorse';
      case MenuQuadrant.puzzle:
        return 'Puzzle';
      case MenuQuadrant.dog:
        return 'Dog';
    }
  }

  String get actionStrategy {
    switch (this) {
      case MenuQuadrant.star:
        return 'ยอดขายสูงและกำไรดี แนะนำรักษามาตรฐานคุณภาพและโปรโมตต่อเนื่อง';
      case MenuQuadrant.plowhorse:
        return 'ขายดีแต่กำไรน้อย แนะนำลดสัดส่วนวัตถุดิบบางตัวหรือขึ้นราคา';
      case MenuQuadrant.puzzle:
        return 'กำไรสูงแต่ขายได้น้อย แนะนำทำการตลาด ปรับตำแหน่งในเมนู หรือจัดเซ็ตคอมโบ';
      case MenuQuadrant.dog:
        return 'ขายไม่ออกและกำไรต่ำ แนะนำพิจารณาตัดออกจากเมนู';
    }
  }

  Color get color {
    switch (this) {
      case MenuQuadrant.star:
        return const Color(0xFF10B981); // Emerald Green
      case MenuQuadrant.plowhorse:
        return const Color(0xFF3B82F6); // Royal Blue
      case MenuQuadrant.puzzle:
        return const Color(0xFFF59E0B); // Amber / Warm Orange
      case MenuQuadrant.dog:
        return const Color(0xFFEF4444); // Crimson Red
    }
  }

  IconData get icon {
    switch (this) {
      case MenuQuadrant.star:
        return Icons.star_rounded;
      case MenuQuadrant.plowhorse:
        return Icons.trending_up_rounded;
      case MenuQuadrant.puzzle:
        return Icons.help_outline_rounded;
      case MenuQuadrant.dog:
        return Icons.warning_amber_rounded;
    }
  }
}
