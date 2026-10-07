import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Streak flame indicator. Plays Google's animated Noto Emoji fire (bundled
/// locally so it still works offline) while [active] is true (streak > 0);
/// otherwise shows a dimmed, static greyscale frame.
class AnimatedFlameIcon extends StatelessWidget {
  final double size;
  final bool active;

  const AnimatedFlameIcon({super.key, required this.size, this.active = true});

  static const _greyscaleMatrix = <double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    final lottie = Lottie.asset(
      'assets/lottie/streak_fire.json',
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: active,
      animate: active,
    );

    if (active) return lottie;

    return Opacity(
      opacity: 0.5,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(_greyscaleMatrix),
        child: lottie,
      ),
    );
  }
}
