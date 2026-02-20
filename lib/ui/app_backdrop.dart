import 'package:flutter/material.dart';

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child, this.topPadding = 0});

  final Widget child;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.primary.withValues(alpha: 0.08),
                  Colors.transparent,
                  scheme.secondary.withValues(alpha: 0.04),
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
        ),
        Positioned(
          top: -70 + topPadding,
          right: -40,
          child: _Bubble(
            size: 220,
            color: scheme.primary.withValues(alpha: 0.13),
          ),
        ),
        Positioned(
          top: 160 + topPadding,
          left: -55,
          child: _Bubble(
            size: 170,
            color: scheme.tertiary.withValues(alpha: 0.1),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
