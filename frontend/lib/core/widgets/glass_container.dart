import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Reusable Frosted Glass Card / Container with razor-sharp borders, subtle glow,
/// and smooth interactive hover feedback (TranslateY -2px, brighter border, and enhanced glow).
/// Styled according to modern dark dashboards (Vercel / React Bits / Linear aesthetics).
class GlassContainer extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? glowColor;
  final double glowOpacity;
  final double glowBlur;
  final VoidCallback? onTap;
  final bool enableHover;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(20.0),
    this.margin,
    this.borderRadius = 16.0,
    this.blur = 14.0,
    this.backgroundColor,
    this.borderColor,
    this.glowColor,
    this.glowOpacity = 0.15,
    this.glowBlur = 20.0,
    this.onTap,
    this.enableHover = true,
  });

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final baseBorderColor = widget.borderColor ?? Colors.white.withValues(alpha: 0.08);
    final hoveredBorderColor = widget.glowColor != null
        ? widget.glowColor!.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.22);
    final effectiveBorderColor = (_isHovered && widget.enableHover) ? hoveredBorderColor : baseBorderColor;

    final effectiveBgColor = widget.backgroundColor ?? Colors.white.withValues(alpha: 0.04);
    final effectiveGlowOpacity = (_isHovered && widget.enableHover)
        ? (widget.glowOpacity * 1.6).clamp(0.0, 0.45)
        : widget.glowOpacity;
    final effectiveGlowBlur = (_isHovered && widget.enableHover)
        ? widget.glowBlur + 8
        : widget.glowBlur;

    Widget container = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(
        0,
        (_isHovered && widget.enableHover) ? -2.0 : 0.0,
        0,
      ),
      width: widget.width,
      height: widget.height,
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          if (widget.glowColor != null)
            BoxShadow(
              color: widget.glowColor!.withValues(alpha: effectiveGlowOpacity),
              blurRadius: effectiveGlowBlur,
              spreadRadius: (_isHovered && widget.enableHover) ? 1 : 0,
              offset: Offset(0, (_isHovered && widget.enableHover) ? 6 : 4),
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: (_isHovered && widget.enableHover) ? 0.45 : 0.35),
              blurRadius: (_isHovered && widget.enableHover) ? 22 : 16,
              offset: Offset(0, (_isHovered && widget.enableHover) ? 6 : 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: (kIsWeb || widget.blur <= 0)
            ? AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: effectiveBgColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: effectiveBorderColor,
                    width: 1.0,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: (_isHovered && widget.enableHover) ? 0.09 : 0.06),
                      Colors.white.withValues(alpha: (_isHovered && widget.enableHover) ? 0.03 : 0.02),
                    ],
                  ),
                ),
                child: widget.child,
              )
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    color: effectiveBgColor,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: effectiveBorderColor,
                      width: 1.0,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: (_isHovered && widget.enableHover) ? 0.09 : 0.06),
                        Colors.white.withValues(alpha: (_isHovered && widget.enableHover) ? 0.03 : 0.02),
                      ],
                    ),
                  ),
                  child: widget.child,
                ),
              ),
      ),
    );

    if (widget.onTap != null) {
      container = InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: container,
      );
    }

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) {
        if (mounted && widget.enableHover) {
          setState(() => _isHovered = true);
        }
      },
      onExit: (_) {
        if (mounted && widget.enableHover) {
          setState(() => _isHovered = false);
        }
      },
      child: container,
    );
  }
}
