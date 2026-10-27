import 'package:flutter/material.dart';

/// Animation helpers for the whole app — no new packages, just
/// Flutter's own animation widgets, so `flutter pub get` stays
/// exactly as before.
///
/// The point is flow, not fireworks:
/// - screens fade + slide in, staggered, instead of popping.
/// - bars and money count up instead of jumping.
/// - tab changes cross-fade instead of snapping.
/// Every helper runs once on first build (FadeSlideIn is
/// Stateful for exactly that reason), so scrolling or a store
/// update does not replay the entrance animation forever.

/// Fade + slide in once, with an optional stagger delay.
/// Wrap list items with increasing delays (index * 60ms) for
/// a flowing, staggered entrance.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double slideDistance;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.slideDistance = 16,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _offset = Tween<Offset>(
      begin: Offset(0, widget.slideDistance / 100),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
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
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

/// A horizontal bar that grows from 0 to [fraction] instead of
/// appearing at full width. Used on Home (category segments are
/// still plain containers, these are the Insights bars) and on
/// Insights category progress.
class AnimatedBar extends StatelessWidget {
  final double fraction;
  final Color color;
  final double height;
  final Duration delay;

  const AnimatedBar({
    super.key,
    required this.fraction,
    required this.color,
    this.height = 8,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0.0,
        end: fraction.clamp(0.0, 1.0).toDouble(),
      ),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.02, 1.0),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height / 2),
            ),
          ),
        );
      },
    );
  }
}

/// Money that counts up from the previous value to the new one,
/// instead of snapping. The balance on Home uses this — adding a
/// transaction visibly moves the number, which is exactly what a
/// viva demo wants to show.
class AnimatedMoney extends StatefulWidget {
  final double value;
  final TextStyle? style;
  final String Function(double) format;

  const AnimatedMoney({
    super.key,
    required this.value,
    required this.format,
    this.style,
  });

  @override
  State<AnimatedMoney> createState() => _AnimatedMoneyState();
}

class _AnimatedMoneyState extends State<AnimatedMoney> {
  double _previous = 0;

  @override
  void didUpdateWidget(AnimatedMoney oldWidget) {
    super.didUpdateWidget(oldWidget);
    _previous = oldWidget.value;
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _previous, end: widget.value),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text(widget.format(value), style: widget.style);
      },
    );
  }
}

/// Slide + fade page route, used for Add / Edit everywhere so
/// opening a form feels like a sheet flowing in, not a hard cut.
/// Use this instead of MaterialPageRoute for Add/Edit.
PageRouteBuilder<void> slideFadeRoute(Widget page) {
  return PageRouteBuilder<void>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.06),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      );
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
