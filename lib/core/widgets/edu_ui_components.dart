import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

import '../../app/theme/edu_note_theme.dart';

/// Micro-bounce / scale down effect on press for high responsiveness
class BounceableTap extends StatefulWidget {
  const BounceableTap({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.96,
    this.duration = const Duration(milliseconds: 100),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;

  @override
  State<BounceableTap> createState() => _BounceableTapState();
}

class _BounceableTapState extends State<BounceableTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onTap != null) _controller.reverse();
  }

  void _onTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Staggered Fade and Slide entrance animation for lists & cards
class StaggeredFadeSlideList extends StatelessWidget {
  const StaggeredFadeSlideList({
    super.key,
    required this.children,
    this.delay = const Duration(milliseconds: 40),
    this.initialDelay = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 380),
    this.curve = Curves.easeOutCubic,
    this.offsetDy = 24.0,
  });

  final List<Widget> children;
  final Duration delay;
  final Duration initialDelay;
  final Duration duration;
  final Curve curve;
  final double offsetDy;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < children.length; i++)
          _StaggeredItem(
            delay: initialDelay + (delay * i),
            duration: duration,
            curve: curve,
            offsetDy: offsetDy,
            child: children[i],
          ),
      ],
    );
  }
}

class _StaggeredItem extends StatefulWidget {
  const _StaggeredItem({
    required this.child,
    required this.delay,
    required this.duration,
    required this.curve,
    required this.offsetDy,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final double offsetDy;

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.offsetDy / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Soft UI Card with subtle border and floating shadow
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = EduNoteColors.surface,
    this.borderColor = EduNoteColors.cardBorder,
    this.borderRadius = 18.0,
    this.shadows = EduNoteShadows.soft,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double borderRadius;
  final List<BoxShadow> shadows;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final container = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: shadows,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap != null) {
      return BounceableTap(onTap: onTap, child: container);
    }
    return container;
  }
}

/// Color vector icon from icones.js.org SVG assets with graceful fallback
class EduColorIcon extends StatelessWidget {
  const EduColorIcon({
    super.key,
    required this.name,
    this.size = 28.0,
    this.fallbackIcon = Icons.stars_rounded,
    this.fallbackColor = EduNoteColors.accent,
  });

  final String name;
  final double size;
  final IconData fallbackIcon;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      placeholderBuilder: (context) => Icon(
        fallbackIcon,
        size: size,
        color: fallbackColor,
      ),
    );
  }
}

/// Lottie Animation State Widget for Empty States, Success, Loading
class EduLottieState extends StatelessWidget {
  const EduLottieState({
    super.key,
    required this.lottieAsset,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.arrow_forward_rounded,
    this.height = 160.0,
    this.repeat = true,
  });

  final String lottieAsset;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;
  final double height;
  final bool repeat;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              lottieAsset,
              height: height,
              repeat: repeat,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: EduNoteColors.accentLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.folder_open_rounded,
                  size: 38,
                  color: EduNoteColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: EduNoteColors.ink,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: EduNoteColors.muted,
                fontSize: 14.5,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 22),
              BounceableTap(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        EduNoteColors.accentGradientStart,
                        EduNoteColors.accentGradientEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: EduNoteShadows.primaryGlow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(actionIcon, size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
