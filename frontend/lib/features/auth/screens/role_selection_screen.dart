import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/user_role_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/capsule_toast.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  UserRole _selectedRole = UserRole.manager;
  String _enteredPin = '';
  bool _hasError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 12.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onRoleSelected(UserRole role) {
    setState(() {
      _selectedRole = role;
      _enteredPin = '';
      _hasError = false;
    });
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 4) return;
    HapticFeedback.selectionClick();
    setState(() {
      _enteredPin += digit;
      _hasError = false;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _hasError = false;
    });
  }

  void _onClearPressed() {
    setState(() {
      _enteredPin = '';
      _hasError = false;
    });
  }

  void _verifyPin({bool bypass = false}) {
    final isValid = bypass ||
        _enteredPin == _selectedRole.pinCode ||
        _enteredPin == '1234'; // Master PIN 1234 always unlocks

    if (isValid) {
      HapticFeedback.mediumImpact();
      ref.read(userRoleProvider.notifier).setRole(_selectedRole);
      ref.read(authProvider.notifier).login();

      CapsuleToast.show(
        context,
        message: 'ยินดีต้อนรับ ${_selectedRole.label}',
        icon: Icons.check_circle_rounded,
        accentColor: _selectedRole.color,
      );

      context.go(_selectedRole.defaultRoute);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
      });
      _shakeController.forward(from: 0.0).then((_) {
        setState(() {
          _enteredPin = '';
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 1080;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: Stack(
        children: [
          // Ambient background glow circles
          Positioned(
            top: -120,
            left: -120,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _selectedRole.color.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Layout Content
          SafeArea(
            child: Column(
              children: [
                // Top App Branding Bar
                _buildTopBrandBar(),

                // Center Content: Wide (Split Row) or Narrow (Scrollable Column)
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: isWide
                          ? _buildWideLayout()
                          : SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 24,
                              ),
                              child: _buildNarrowLayout(),
                            ),
                    ),
                  ),
                ),

                // Footer Info Bar
                _buildFooterBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBrandBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo Icon with Gradient
          Container(
            width: 44,
            height: 44,
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
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    AppConstants.appName,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'v2.4 Pro',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryNeon,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Food Cost Analyzer & Kasavana-Smith Intelligence',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Live PostgreSQL & Cloud status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'PostgreSQL 60-Day Data Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: 3 Role Cards
          Expanded(
            flex: 6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderTexts(),
                const SizedBox(height: 24),
                _buildRoleCardsList(),
              ],
            ),
          ),
          const SizedBox(width: 36),
          // Right: PIN Verification Pad
          Expanded(
            flex: 4,
            child: Center(
              child: _buildPinPadCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildHeaderTexts(),
        const SizedBox(height: 24),
        _buildRoleCardsList(),
        const SizedBox(height: 32),
        _buildPinPadCard(),
      ],
    );
  }

  Widget _buildHeaderTexts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _selectedRole.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _selectedRole.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_person_rounded, size: 14, color: _selectedRole.color),
              const SizedBox(width: 6),
              Text(
                'ระบบควบคุมสิทธิ์ตามบทบาท (Role-Based Access Control)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _selectedRole.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'เลือกสถานะเพื่อเข้าสู่ระบบงาน',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'แตะเลือกตำแหน่งของคุณ จากนั้นใส่รหัส PIN 4 หลัก เพื่อเข้าใช้งานหน้าต่างที่ได้รับอนุญาต',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF94A3B8),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCardsList() {
    return Column(
      children: [
        _buildRoleCard(
          role: UserRole.manager,
          title: 'ผู้จัดการร้าน (Restaurant Manager)',
          subtitle: 'เข้าถึงภาพรวมแดชบอร์ด, วิเคราะห์เมทริกซ์ 4 Quadrants, สต็อก & วางแผนสูตร',
          highlights: ['Dashboard & Kasavana Matrix', 'Recipe Builder & BOM', 'AI Waste Forecast', 'What-If Simulation'],
          routeLabel: '/dashboard',
        ),
        const SizedBox(height: 16),
        _buildRoleCard(
          role: UserRole.kitchen,
          title: 'หัวหน้าเชฟ & ห้องครัว (Kitchen Chef)',
          subtitle: 'จอคิวอาหาร Real-time (KDS), ตัวคุมสัดส่วนตักปรุง (Portion Guide) และเวลาทำอาหาร',
          highlights: ['จอคิวครัว Real-time (KDS)', 'คู่มือสัดส่วนตักปรุง (Portion)', 'เสียงกระดิ่งเตือนออเดอร์เข้า', 'อัปเดตสถานะปรุงเสร็จ'],
          routeLabel: '/kds',
        ),
        const SizedBox(height: 16),
        _buildRoleCard(
          role: UserRole.cashier,
          title: 'แคชเชียร์ & หน้าร้าน (Cashier / POS)',
          subtitle: 'ระบบขายหน้าร้านด่วน (Quick POS), รับออเดอร์ตัดสต็อกอัตโนมัติ และดูประวัติบิล',
          highlights: ['เปิดบิลขายด่วน (Quick POS)', 'ตัดสต็อกอัตโนมัติทันที', 'ระบบแจ้งเตือนสต็อกไม่พอ', 'ประวัติบิลย้อนหลัง 60 วัน'],
          routeLabel: '/pos',
        ),
      ],
    );
  }

  Widget _buildRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required List<String> highlights,
    required String routeLabel,
  }) {
    final isSelected = _selectedRole == role;
    final color = role.color;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _onRoleSelected(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.10)
                : const Color(0xFF1E293B).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : const Color(0xFF334155),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.22),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji Avatar Icon Box
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color.withValues(alpha: 0.5) : const Color(0xFF334155),
                  ),
                ),
                child: Center(
                  child: Text(
                    role.emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Role Description & Highlights
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        // Default Route Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected ? color.withValues(alpha: 0.4) : const Color(0xFF334155),
                            ),
                          ),
                          child: Text(
                            routeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: isSelected ? color : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF94A3B8),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Highlights Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: highlights.map((hl) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.12)
                                : const Color(0xFF0F172A).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 12,
                                color: isSelected ? color : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                hl,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Selection Checkmark Circle
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? color : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFF475569),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinPadCard() {
    final color = _selectedRole.color;

    return Container(
      constraints: const BoxConstraints(maxWidth: 350),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 35,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Role Header Banner
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_selectedRole.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _selectedRole.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'กรุณากรอกรหัสผ่าน PIN 4 หลัก',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 20),

          // 4-Dot Animated PIN Indicator
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              final offset = _hasError
                  ? math.sin(_shakeAnimation.value * math.pi) * 8.0
                  : 0.0;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isFilled = index < _enteredPin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hasError
                            ? const Color(0xFFEF4444)
                            : (isFilled ? color : const Color(0xFF1E293B)),
                        border: Border.all(
                          color: _hasError
                              ? const Color(0xFFEF4444)
                              : (isFilled ? color : const Color(0xFF475569)),
                          width: 2,
                        ),
                        boxShadow: isFilled && !_hasError
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Error / Helper Hint Text
          if (_hasError)
            Text(
              'รหัสผ่านไม่ถูกต้อง กรุณาลองใหม่ (รหัส: ${_selectedRole.pinCode})',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'รหัสทดสอบสาธิต: ${_selectedRole.pinCode}',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 22),

          // Numeric Keypad Grid
          _buildNumericKeypad(),
          const SizedBox(height: 18),

          // Quick Demo Bypass Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _verifyPin(bypass: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                'เข้าสู่ระบบทันที (ข้าม PIN สำหรับเดโม)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Column(
      children: [
        _buildKeyRow(['1', '2', '3']),
        const SizedBox(height: 10),
        _buildKeyRow(['4', '5', '6']),
        const SizedBox(height: 10),
        _buildKeyRow(['7', '8', '9']),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Clear Key
            _buildSpecialKey(
              icon: Icons.clear_all_rounded,
              onTap: _onClearPressed,
              tooltip: 'ล้างข้อมูล',
            ),
            const SizedBox(width: 8),
            // Zero Key
            _buildDigitKey('0'),
            const SizedBox(width: 8),
            // Backspace Key
            _buildSpecialKey(
              icon: Icons.backspace_outlined,
              onTap: _onBackspacePressed,
              tooltip: 'ลบ',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((digit) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildDigitKey(digit),
        );
      }).toList(),
    );
  }

  Widget _buildDigitKey(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onDigitPressed(digit),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 58,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 58,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Center(
            child: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            '© 2026 MenuEng Pro — Intelligent Restaurant Engineering Platform',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          Text(
            'CS67 Food Cost Analyzer Project',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
