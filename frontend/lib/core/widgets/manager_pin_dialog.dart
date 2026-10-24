import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_role_provider.dart';
import '../theme/app_theme.dart';
import 'capsule_toast.dart';

/// Opens the Quick PIN Pad Modal to verify manager access
Future<bool> showManagerPinDialog(
  BuildContext context, {
  WidgetRef? ref,
  String? targetTitle,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => ManagerPinDialog(targetTitle: targetTitle),
  );

  final isAuthorized = result == true;
  if (isAuthorized && ref != null && context.mounted) {
    ref.read(userRoleProvider.notifier).setRole(UserRole.manager);
    CapsuleToast.showSuccess(
      context,
      'ปลดล็อกสิทธิ์ผู้จัดการ (Manager) เรียบร้อยแล้ว',
      title: 'ยืนยันรหัสผ่านสำเร็จ',
    );
  }

  return isAuthorized;
}

class ManagerPinDialog extends StatefulWidget {
  final String? targetTitle;
  final String correctPin;

  const ManagerPinDialog({
    super.key,
    this.targetTitle,
    this.correctPin = '1234',
  });

  @override
  State<ManagerPinDialog> createState() => _ManagerPinDialogState();
}

class _ManagerPinDialogState extends State<ManagerPinDialog>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  bool _isError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
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

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 4) return;
    setState(() {
      _isError = false;
      _enteredPin += digit;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _isError = false;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  void _onClearPressed() {
    setState(() {
      _isError = false;
      _enteredPin = '';
    });
  }

  void _onQuickBypassPressed() {
    setState(() {
      _isError = false;
      _enteredPin = widget.correctPin;
    });
    _verifyPin();
  }

  void _verifyPin() {
    if (_enteredPin == widget.correctPin) {
      Navigator.of(context).pop(true);
    } else {
      _shakeController.forward(from: 0.0);
      setState(() {
        _isError = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _enteredPin = '';
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: 360,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF161B26).withValues(alpha: 0.94),
                    const Color(0xFF0F172A).withValues(alpha: 0.98),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _isError
                      ? AppTheme.danger.withValues(alpha: 0.6)
                      : AppTheme.primary.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isError
                        ? AppTheme.danger.withValues(alpha: 0.25)
                        : AppTheme.primary.withValues(alpha: 0.2),
                    blurRadius: 36,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.7),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Lock Icon Badge
                  Container(
                    width: 54,
                    height: 54,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isError
                          ? AppTheme.danger.withValues(alpha: 0.15)
                          : AppTheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isError
                            ? AppTheme.danger.withValues(alpha: 0.5)
                            : AppTheme.primaryNeon.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isError
                              ? AppTheme.danger.withValues(alpha: 0.2)
                              : AppTheme.primaryNeon.withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isError ? Icons.lock_open_rounded : Icons.lock_rounded,
                      size: 26,
                      color: _isError ? AppTheme.danger : AppTheme.primaryNeon,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Titles
                  const Text(
                    'ยืนยันรหัสผ่านผู้จัดการ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.targetTitle != null
                        ? 'ต้องใช้สิทธิ์ผู้จัดการเพื่อเข้าสู่ "${widget.targetTitle}"'
                        : 'ใส่รหัสผ่าน 4 หลัก เพื่อปลดล็อกสิทธิ์ผู้จัดการ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4-Dot PIN Indicator with Shake Animation
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final isFilled = index < _enteredPin.length;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isError
                                ? AppTheme.danger
                                : (isFilled ? AppTheme.primaryNeon : Colors.transparent),
                            border: Border.all(
                              color: _isError
                                  ? AppTheme.danger
                                  : (isFilled ? AppTheme.primaryNeon : AppTheme.textMuted),
                              width: 2,
                            ),
                            boxShadow: isFilled && !_isError
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryNeon.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),
                  ),

                  // Error Text or Hint
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 20,
                    child: _isError
                        ? const Text(
                            'รหัสผ่านไม่ถูกต้อง กรุณาลองใหม่ (รหัส: 1234)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.danger,
                            ),
                          )
                        : Text(
                            'รหัสผ่านเริ่มต้นสำหรับสาธิต: 1234',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textMuted.withValues(alpha: 0.8),
                            ),
                          ),
                  ),
                  const SizedBox(height: 14),

                  // Number Keypad (1 to 9, C, 0, Backspace)
                  _buildKeypad(),
                  const SizedBox(height: 16),

                  // Quick Demo Shortcut Button (1-Click 1234 Bypass)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      key: const Key('pin_bypass_button'),
                      onPressed: _onQuickBypassPressed,
                      icon: const Text('⚡', style: TextStyle(fontSize: 14)),
                      label: const Text(
                        'กรอกรหัสจำลอง 1234 ด่วน (Demo Bypass)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryNeon,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: AppTheme.primary.withValues(alpha: 0.25),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Cancel Button
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'ยกเลิก',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        const SizedBox(height: 10),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: 10),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSpecialKey(
              keyName: 'pin_key_clear',
              label: 'C',
              color: AppTheme.textMuted,
              onTap: _onClearPressed,
            ),
            _buildDigitKey('0'),
            _buildSpecialKey(
              keyName: 'pin_key_backspace',
              icon: Icons.backspace_outlined,
              color: AppTheme.textMuted,
              onTap: _onBackspacePressed,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildDigitKey(d)).toList(),
    );
  }

  Widget _buildDigitKey(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('pin_key_$digit'),
        onTap: () => _onDigitPressed(digit),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: AppTheme.border,
              width: 1,
            ),
          ),
          child: Text(
            digit,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey({
    required String keyName,
    String? label,
    IconData? icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key(keyName),
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.02),
          ),
          child: label != null
              ? Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                )
              : Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
