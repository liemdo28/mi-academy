import 'package:flutter/material.dart';

/// Builder that replaces animations with instant transitions when
/// reduced motion is enabled.
///
/// When [reduceMotion] is true or [animationBuilder] is null, [builder]
/// is used directly (instant, no animation). Otherwise [animationBuilder]
/// receives an animation value from 0→1 over [duration].
class ReducedMotionBuilder extends StatefulWidget {
  const ReducedMotionBuilder({
    super.key,
    required this.reduceMotion,
    required this.builder,
    this.animationBuilder,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  final bool reduceMotion;
  final WidgetBuilder builder;
  final Widget Function(double value)? animationBuilder;
  final Duration duration;
  final Curve curve;

  @override
  State<ReducedMotionBuilder> createState() => _ReducedMotionBuilderState();
}

class _ReducedMotionBuilderState extends State<ReducedMotionBuilder>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _animation;

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion && widget.animationBuilder != null) {
      _controller = AnimationController(
        vsync: this,
        duration: widget.duration,
      );
      _animation = CurvedAnimation(
        parent: _controller!..forward(),
        curve: widget.curve,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ReducedMotionBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion && !oldWidget.reduceMotion) {
      _controller?.stop();
    } else if (!widget.reduceMotion && oldWidget.reduceMotion) {
      _controller?.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion || widget.animationBuilder == null) {
      return widget.builder(context);
    }

    return AnimatedBuilder(
      animation: _animation!,
      builder: (context, child) {
        return widget.animationBuilder!(_animation!.value);
      },
    );
  }
}

/// Internal [AnimatedWidget] that rebuilds on every animation tick.
class AnimatedBuilder extends AnimatedWidget {
  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
  }) : super(listenable: animation);

  final Widget Function(BuildContext context, Widget? child) builder;

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}

/// A widget that replaces [AnimatedContainer] with a static [Container]
/// when reduced motion is preferred.
class MotionAwareContainer extends StatelessWidget {
  const MotionAwareContainer({
    super.key,
    required this.reduceMotion,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    required this.child,
    this.constraints,
    this.alignment,
    this.padding,
    this.color,
    this.decoration,
    this.foregroundDecoration,
    this.width,
    this.height,
    this.margin,
    this.transform,
    this.transformAlignment,
    this.clipBehavior = Clip.none,
  });

  final bool reduceMotion;
  final Duration duration;
  final Curve curve;
  final Widget child;
  final BoxConstraints? constraints;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Decoration? decoration;
  final Decoration? foregroundDecoration;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final Matrix4? transform;
  final AlignmentGeometry? transformAlignment;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) {
      return Container(
        constraints: constraints,
        alignment: alignment,
        padding: padding,
        color: color,
        decoration: decoration,
        foregroundDecoration: foregroundDecoration,
        width: width,
        height: height,
        margin: margin,
        transform: transform,
        transformAlignment: transformAlignment,
        clipBehavior: clipBehavior,
        child: child,
      );
    }

    return AnimatedContainer(
      duration: duration,
      curve: curve,
      constraints: constraints,
      alignment: alignment,
      padding: padding,
      color: color,
      decoration: decoration,
      foregroundDecoration: foregroundDecoration,
      width: width,
      height: height,
      margin: margin,
      transform: transform,
      transformAlignment: transformAlignment,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

/// A widget that replaces [AnimatedOpacity] with static opacity.
class MotionAwareOpacity extends StatelessWidget {
  const MotionAwareOpacity({
    super.key,
    required this.reduceMotion,
    required this.opacity,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.alwaysIncludeSemantics = false,
  });

  final bool reduceMotion;
  final double opacity;
  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool alwaysIncludeSemantics;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) {
      return Opacity(
        opacity: opacity,
        alwaysIncludeSemantics: alwaysIncludeSemantics,
        child: child,
      );
    }

    return AnimatedOpacity(
      opacity: opacity,
      duration: duration,
      curve: curve,
      alwaysIncludeSemantics: alwaysIncludeSemantics,
      child: child,
    );
  }
}

/// A widget that replaces [AnimatedScale] with static scale.
class MotionAwareScale extends StatelessWidget {
  const MotionAwareScale({
    super.key,
    required this.reduceMotion,
    required this.scale,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.alignment = Alignment.center,
  });

  final bool reduceMotion;
  final double scale;
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) {
      return Transform.scale(
        scale: scale,
        alignment: alignment,
        child: child,
      );
    }

    return AnimatedScale(
      scale: scale,
      duration: duration,
      curve: curve,
      alignment: alignment,
      child: child,
    );
  }
}

/// A widget that replaces [AnimatedPadding] with static padding.
class MotionAwarePadding extends StatelessWidget {
  const MotionAwarePadding({
    super.key,
    required this.reduceMotion,
    required this.padding,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  final bool reduceMotion;
  final EdgeInsetsGeometry padding;
  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) {
      return Padding(
        padding: padding,
        child: child,
      );
    }

    return AnimatedPadding(
      padding: padding,
      duration: duration,
      curve: curve,
      child: child,
    );
  }
}
