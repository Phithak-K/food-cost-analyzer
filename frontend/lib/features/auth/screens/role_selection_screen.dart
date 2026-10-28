import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/system_status_provider.dart';
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
  final FocusNode _keyboardFocusNode = FocusNode();

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 12.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);

    // Auto-focus keyboard listener for desktop numpad support
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _keyboardFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _onRoleSelected(UserRole role) {
    if (_selectedRole == role) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedRole = role;
      _enteredPin = '';
      _hasError = false;
    });
    _keyboardFocusNode.requestFocus();
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 4) return;
    HapticFeedback.lightImpact();
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
    HapticFeedback.lightImpact();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _hasError = false;
    });
  }

  void _onClearPressed() {
    HapticFeedback.mediumImpact();
    setState(() {
      _enteredPin = '';
      _hasError = false;
    });
  }

  void _quickFillPinAndSubmit() {
    HapticFeedback.mediumImpact();
    setState(() {
      _enteredPin = _selectedRole.pinCode;
      _hasError = false;
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _verifyPin();
    });
  }

  void _directLoginWithRole(UserRole role) {
    HapticFeedback.mediumImpact();
    ref.read(userRoleProvider.notifier).setRole(role);
    ref.read(authProvider.notifier).login();

    CapsuleToast.show(
      context,
      message: 'ยินดีต้อนรับ ${role.label}',
      icon: Icons.check_circle_rounded,
      accentColor: role.color,
    );

    context.go(role.defaultRoute);
  }

  void _verifyPin({bool bypass = false}) {
    final isValid = bypass ||
        _enteredPin == _selectedRole.pinCode ||
        _enteredPin == '1234'; // Master PIN 1234 always unlocks

    if (isValid) {
      HapticFeedback.mediumImpact();
      _directLoginWithRole(_selectedRole);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _hasError = true;
      });
      _shakeController.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() {
            _enteredPin = '';
          });
        }
      });
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      _onDigitPressed('0');
    } else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      _onDigitPressed('1');
    } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      _onDigitPressed('2');
    } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      _onDigitPressed('3');
    } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      _onDigitPressed('4');
    } else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
      _onDigitPressed('5');
    } else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
      _onDigitPressed('6');
    } else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
      _onDigitPressed('7');
    } else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
      _onDigitPressed('8');
    } else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
      _onDigitPressed('9');
    } else if (key == LogicalKeyboardKey.backspace) {
      _onBackspacePressed();
    } else if (key == LogicalKeyboardKey.escape) {
      _onClearPressed();
    } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (_enteredPin.length == 4) {
        _verifyPin();
      } else {
        _verifyPin(bypass: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktopSplit = size.width >= 820 && size.height >= 560;
    final roleColor = _selectedRole.color;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        body: Stack(
          children: [
            // Dynamic Ambient Background Glow (transitions with selected role)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              top: -100,
              left: isDesktopSplit ? -80 : -140,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 480,
                height: 480,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      roleColor.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              bottom: -120,
              right: isDesktopSplit ? -60 : -140,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 520,
                height: 520,
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

            // Main Viewport Container
            SafeArea(
              child: Column(
                children: [
                  // Sleek Top Header
                  _buildHeaderBar(),

                  // Center Stage (Zero-Scroll on Standard Displays)
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: isDesktopSplit
                            ? _buildSplitLayout()
                            : SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: _buildCompactVerticalLayout(),
                              ),
                      ),
                    ),
                  ),

                  // Compact Footer Bar
                  _buildFooterBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Top App Branding & Live Health Status Bar
  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1120),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryNeon],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              AppConstants.appName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'v2.4 Pro',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.primaryNeon,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Food Cost Analyzer & Kasavana-Smith Intelligence',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SystemStatusBadge(),
        ],
      ),
    );
  }

  // 2-Column Split Layout for Desktop / Half-Screen Snapped Windows
  Widget _buildSplitLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Roles Selector Column (58% width)
          Expanded(
            flex: 58,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderBadgeAndTitle(),
                const SizedBox(height: 16),
                _buildRoleCardsList(),
              ],
            ),
          ),
          const SizedBox(width: 28),
          // Right: PIN Security Terminal (42% width)
          Expanded(
            flex: 42,
            child: Center(
              child: _buildPosPinTerminal(),
            ),
          ),
        ],
      ),
    );
  }

  // Compact Layout for Very Narrow / Mobile screens
  Widget _buildCompactVerticalLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildHeaderBadgeAndTitle(),
        const SizedBox(height: 16),
        _buildRoleCardsList(),
        const SizedBox(height: 20),
        _buildPosPinTerminal(),
      ],
    );
  }

  Widget _buildHeaderBadgeAndTitle() {
    final color = _selectedRole.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_rounded, size: 13, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'ระบบควบคุมสิทธิ์ตามบทบาท (Role-Based Access Control)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'เลือกสถานะเพื่อเข้าสู่ระบบงาน',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'คลิกเลือกตำแหน่งเพื่อใส่รหัส PIN หรือแตะปุ่ม "เข้าด่วน" เพื่อเริ่มใช้งานทันที',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF94A3B8),
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCardsList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStreamlinedRoleCard(
          role: UserRole.manager,
          title: 'ผู้จัดการร้าน (Restaurant Manager)',
          subtitle: 'ภาพรวมแดชบอร์ดเมทริกซ์ 4 Quadrants, สต็อกวัตถุดิบ & แผนสูตรอาหาร',
          routeLabel: '/dashboard',
          features: ['Dashboard & Kasavana', 'Recipe & BOM', 'AI Forecast'],
        ),
        const SizedBox(height: 10),
        _buildStreamlinedRoleCard(
          role: UserRole.kitchen,
          title: 'หัวหน้าเชฟ & ห้องครัว (Kitchen Chef)',
          subtitle: 'จอคิวอาหาร Real-time (KDS), ตัวคุมสัดส่วนปรุง (Portion Guide) และจับเวลา',
          routeLabel: '/kds',
          features: ['Kitchen Display (KDS)', 'Portion Guide', 'กระดิ่งเตือนออเดอร์'],
        ),
        const SizedBox(height: 10),
        _buildStreamlinedRoleCard(
          role: UserRole.cashier,
          title: 'แคชเชียร์ & หน้าร้าน (Cashier / POS)',
          subtitle: 'ระบบขายหน้าร้านด่วน (Quick POS), รับออเดอร์ตัดสต็อก และดูประวัติบิล',
          routeLabel: '/pos',
          features: ['Quick POS หน้าร้าน', 'ตัดสต็อกอัตโนมัติ', 'ประวัติบิล 60 วัน'],
        ),
      ],
    );
  }

  // Streamlined, High-Aesthetic Role Card
  Widget _buildStreamlinedRoleCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required String routeLabel,
    required List<String> features,
  }) {
    final isSelected = _selectedRole == role;
    final color = role.color;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _onRoleSelected(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : const Color(0xFF131D31).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : const Color(0xFF1E293B),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    const BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Emoji Avatar Squircle with Ambient Glow
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.22)
                      : const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color.withValues(alpha: 0.6) : const Color(0xFF334155),
                  ),
                ),
                child: Center(
                  child: Text(
                    role.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title, Subtitle, and Feature Tags
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        // Route Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1120),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isSelected
                                  ? color.withValues(alpha: 0.4)
                                  : const Color(0xFF334155),
                            ),
                          ),
                          child: Text(
                            routeLabel,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontFamily: 'monospace',
                              color: isSelected ? color : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF94A3B8),
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: features.map((feat) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.1)
                                : const Color(0xFF0B1120),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            feat,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? color : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // 1-Click Quick Demo Login Button directly on Card
              Tooltip(
                message: 'คลิกเข้าใช้งาน ${role.label} ทันทีโดยไม่ต้องใส่รหัส PIN',
                child: InkWell(
                  onTap: () => _directLoginWithRole(role),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.25)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? color : const Color(0xFF334155),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 14,
                          color: isSelected ? color : const Color(0xFFCBD5E1),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'เข้าด่วน',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? color : const Color(0xFFCBD5E1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tactile Glassmorphism POS Security Keypad Terminal
  Widget _buildPosPinTerminal() {
    final color = _selectedRole.color;

    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF131D31),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.16),
            blurRadius: 32,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Station Identity Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_selectedRole.emoji, style: const TextStyle(fontSize: 20)),
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
          const SizedBox(height: 3),
          const Text(
            'ใส่รหัส PIN 4 หลักเพื่อยืนยันสถานะ',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),

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
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 7),
                      width: 16,
                      height: 16,
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
                                  color: color.withValues(alpha: 0.5),
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
          const SizedBox(height: 10),

          // Clickable Demo Chip (Auto-fill PIN on tap)
          if (_hasError)
            const Text(
              'รหัสผ่านไม่ถูกต้อง กรุณาลองใหม่',
              style: TextStyle(
                fontSize: 11.5,
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            InkWell(
              onTap: _quickFillPinAndSubmit,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_rounded, size: 12, color: color),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'รหัส: ${_selectedRole.pinCode} (แตะเติม)',
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),

          // Numeric Keypad Grid
          _buildNumericKeypad(),
          const SizedBox(height: 14),

          // Large Direct Bypass Login Button
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: () => _verifyPin(bypass: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text(
                'เข้าสู่ระบบทันที (ข้าม PIN)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '💡 สามารถพิมพ์ตัวเลข 0-9 บนคีย์บอร์ดได้ทันที',
            style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Column(
      children: [
        _buildKeyRow(['1', '2', '3'], ['', 'ABC', 'DEF']),
        const SizedBox(height: 8),
        _buildKeyRow(['4', '5', '6'], ['GHI', 'JKL', 'MNO']),
        const SizedBox(height: 8),
        _buildKeyRow(['7', '8', '9'], ['PQRS', 'TUV', 'WXYZ']),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Clear Key
            _buildSpecialKey(
              icon: Icons.clear_all_rounded,
              onTap: _onClearPressed,
              tooltip: 'ล้างข้อมูล (Esc)',
            ),
            const SizedBox(width: 8),
            // Zero Key
            _buildDigitKey('0', '+'),
            const SizedBox(width: 8),
            // Backspace Key
            _buildSpecialKey(
              icon: Icons.backspace_outlined,
              onTap: _onBackspacePressed,
              tooltip: 'ลบ (Backspace)',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyRow(List<String> digits, List<String> subLabels) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(digits.length, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildDigitKey(digits[index], subLabels[index]),
        );
      }),
    );
  }

  Widget _buildDigitKey(String digit, String subLabel) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onDigitPressed(digit),
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 58,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                digit,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              if (subLabel.isNotEmpty)
                Text(
                  subLabel,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
            ],
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
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            width: 58,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Center(
              child: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1120),
        border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Flexible(
            child: Text(
              '© 2026 MenuEng Pro — Intelligent Restaurant Engineering Platform',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 12),
          Text(
            'CS67 Food Cost Analyzer Project',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
