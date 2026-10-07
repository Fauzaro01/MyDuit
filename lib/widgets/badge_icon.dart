import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// The glyph drawn inside a badge medallion. Each one is hand-drawn with
/// Canvas paths rather than an emoji/stock icon, so the achievement set has
/// its own distinct visual identity.
enum BadgeIconType {
  sprout,
  flame,
  bolt,
  crown,
  legend,
  gem,
  target,
  trophy,
  dove,
  shield,
  scaleCoin,
}

const Map<BadgeIconType, List<Color>> _badgeGradients = {
  BadgeIconType.sprout: [Color(0xFF4ADE80), Color(0xFF16A34A)],
  BadgeIconType.flame: [Color(0xFFFF9A3D), Color(0xFFFF5400)],
  BadgeIconType.bolt: [Color(0xFFFDE047), Color(0xFFD97706)],
  BadgeIconType.crown: [Color(0xFFFFD873), Color(0xFFB8860B)],
  BadgeIconType.legend: [Color(0xFFEF4444), Color(0xFF7F1D1D)],
  BadgeIconType.gem: [Color(0xFF67E8F9), Color(0xFF0E7490)],
  BadgeIconType.target: [Color(0xFF4AEDC4), Color(0xFF0D9373)],
  BadgeIconType.trophy: [Color(0xFFFFD873), Color(0xFF0D9373)],
  BadgeIconType.dove: [Color(0xFFC4B5FD), Color(0xFF7C3AED)],
  BadgeIconType.shield: [Color(0xFF60A5FA), Color(0xFF1D4ED8)],
  BadgeIconType.scaleCoin: [Color(0xFF34D399), Color(0xFF047857)],
};

const List<Color> _lockedGradient = [Color(0xFFB0B3B8), Color(0xFF6B7280)];

/// A circular medallion with a hand-drawn glyph — the achievement icon used
/// across the Pencapaian & Streak screen.
class BadgeIcon extends StatelessWidget {
  final BadgeIconType type;
  final bool locked;
  final double size;

  const BadgeIcon({
    super.key,
    required this.type,
    required this.locked,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BadgeIconPainter(type: type, locked: locked),
    );
  }
}

class _BadgeIconPainter extends CustomPainter {
  final BadgeIconType type;
  final bool locked;

  _BadgeIconPainter({required this.type, required this.locked});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final colors = locked ? _lockedGradient : (_badgeGradients[type] ?? _lockedGradient);
    canvas.drawCircle(c, r, Paint()..shader = ui.Gradient.radial(c, r, colors));
    canvas.drawCircle(
      c,
      r * 0.92,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.07
        ..color = Colors.white.withValues(alpha: 0.25),
    );

    const glyphColor = Colors.white;

    if (locked) {
      _paintLock(canvas, c, r, glyphColor);
      return;
    }

    switch (type) {
      case BadgeIconType.sprout:
        _paintSprout(canvas, c, r, glyphColor);
      case BadgeIconType.flame:
        _paintFlame(canvas, c, r, glyphColor);
      case BadgeIconType.bolt:
        _paintBolt(canvas, c, r, glyphColor);
      case BadgeIconType.crown:
        _paintCrown(canvas, c, r, glyphColor);
      case BadgeIconType.legend:
        _paintLegend(canvas, c, r, glyphColor);
      case BadgeIconType.gem:
        _paintGem(canvas, c, r, glyphColor);
      case BadgeIconType.target:
        _paintTarget(canvas, c, r, glyphColor);
      case BadgeIconType.trophy:
        _paintTrophy(canvas, c, r, glyphColor);
      case BadgeIconType.dove:
        _paintDove(canvas, c, r, glyphColor);
      case BadgeIconType.shield:
        _paintShield(canvas, c, r, glyphColor);
      case BadgeIconType.scaleCoin:
        _paintScaleCoin(canvas, c, r, glyphColor);
    }
  }

  @override
  bool shouldRepaint(covariant _BadgeIconPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.locked != locked;
}

void _paintLock(Canvas canvas, Offset c, double r, Color color) {
  final fill = Paint()..color = color;
  final stroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = r * 0.11
    ..strokeCap = StrokeCap.round;
  canvas.drawArc(
    Rect.fromCenter(center: Offset(c.dx, c.dy - r * 0.08), width: r * 0.4, height: r * 0.5),
    pi,
    pi,
    false,
    stroke,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(c.dx, c.dy + r * 0.2), width: r * 0.56, height: r * 0.42),
      Radius.circular(r * 0.08),
    ),
    fill,
  );
}

Path flamePath(Offset c, double r) {
  return Path()
    ..moveTo(c.dx, c.dy + r * 0.42)
    ..quadraticBezierTo(c.dx - r * 0.35, c.dy + r * 0.18, c.dx - r * 0.22, c.dy - r * 0.08)
    ..quadraticBezierTo(c.dx - r * 0.3, c.dy - r * 0.28, c.dx - r * 0.04, c.dy - r * 0.42)
    ..quadraticBezierTo(c.dx + r * 0.06, c.dy - r * 0.2, c.dx + r * 0.02, c.dy - r * 0.04)
    ..quadraticBezierTo(c.dx + r * 0.26, c.dy - r * 0.14, c.dx + r * 0.22, c.dy + r * 0.14)
    ..quadraticBezierTo(c.dx + r * 0.16, c.dy + r * 0.32, c.dx, c.dy + r * 0.42)
    ..close();
}

void _paintSprout(Canvas canvas, Offset c, double r, Color color) {
  final fill = Paint()..color = color;
  final stroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = r * 0.1
    ..strokeCap = StrokeCap.round;
  canvas.drawPath(
    Path()
      ..moveTo(c.dx, c.dy + r * 0.38)
      ..quadraticBezierTo(c.dx, c.dy + r * 0.05, c.dx, c.dy - r * 0.3),
    stroke,
  );
  canvas.save();
  canvas.translate(c.dx - r * 0.14, c.dy - r * 0.02);
  canvas.rotate(-0.6);
  canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 0.52, height: r * 0.26), fill);
  canvas.restore();
  canvas.save();
  canvas.translate(c.dx + r * 0.16, c.dy - r * 0.14);
  canvas.rotate(0.6);
  canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 0.52, height: r * 0.26), fill);
  canvas.restore();
}

void _paintFlame(Canvas canvas, Offset c, double r, Color color) {
  canvas.drawPath(flamePath(c, r), Paint()..color = color);
}

void _paintBolt(Canvas canvas, Offset c, double r, Color color) {
  final path = Path()
    ..moveTo(c.dx + r * 0.12, c.dy - r * 0.42)
    ..lineTo(c.dx - r * 0.28, c.dy + r * 0.05)
    ..lineTo(c.dx - r * 0.02, c.dy + r * 0.05)
    ..lineTo(c.dx - r * 0.12, c.dy + r * 0.42)
    ..lineTo(c.dx + r * 0.28, c.dy - r * 0.08)
    ..lineTo(c.dx + r * 0.02, c.dy - r * 0.08)
    ..close();
  canvas.drawPath(path, Paint()..color = color);
}

void _paintCrown(Canvas canvas, Offset c, double r, Color color) {
  final fill = Paint()..color = color;
  final baseY = c.dy + r * 0.3;
  final path = Path()
    ..moveTo(c.dx - r * 0.4, baseY)
    ..lineTo(c.dx - r * 0.4, c.dy)
    ..lineTo(c.dx - r * 0.22, c.dy + r * 0.1)
    ..lineTo(c.dx - r * 0.08, c.dy - r * 0.35)
    ..lineTo(c.dx, c.dy + r * 0.05)
    ..lineTo(c.dx + r * 0.08, c.dy - r * 0.35)
    ..lineTo(c.dx + r * 0.22, c.dy + r * 0.1)
    ..lineTo(c.dx + r * 0.4, c.dy)
    ..lineTo(c.dx + r * 0.4, baseY)
    ..close();
  canvas.drawPath(path, fill);
}

void _paintLegend(Canvas canvas, Offset c, double r, Color color) {
  // Smaller flame, scaled around its own center so the sparkle ring has room.
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.scale(0.7);
  canvas.translate(-c.dx, -c.dy);
  canvas.drawPath(flamePath(c, r), Paint()..color = color);
  canvas.restore();

  final sparkFill = Paint()..color = color;
  for (final angle in const [0.0, pi / 2, pi, pi * 1.5]) {
    final p = Offset(c.dx + cos(angle) * r * 0.62, c.dy + sin(angle) * r * 0.62);
    _drawSparkle(canvas, p, r * 0.09, sparkFill);
  }
}

void _drawSparkle(Canvas canvas, Offset p, double s, Paint fill) {
  final path = Path()
    ..moveTo(p.dx, p.dy - s)
    ..lineTo(p.dx + s * 0.35, p.dy)
    ..lineTo(p.dx, p.dy + s)
    ..lineTo(p.dx - s * 0.35, p.dy)
    ..close();
  canvas.drawPath(path, fill);
}

void _paintGem(Canvas canvas, Offset c, double r, Color color) {
  final fill = Paint()..color = color;
  final top = Offset(c.dx, c.dy - r * 0.4);
  final left = Offset(c.dx - r * 0.38, c.dy - r * 0.05);
  final right = Offset(c.dx + r * 0.38, c.dy - r * 0.05);
  final bottom = Offset(c.dx, c.dy + r * 0.42);
  final path = Path()
    ..moveTo(top.dx, top.dy)
    ..lineTo(right.dx, right.dy)
    ..lineTo(bottom.dx, bottom.dy)
    ..lineTo(left.dx, left.dy)
    ..close();
  canvas.drawPath(path, fill);

  final facet = Paint()
    ..color = Colors.black.withValues(alpha: 0.12)
    ..style = PaintingStyle.stroke
    ..strokeWidth = r * 0.03;
  final waist = Offset(c.dx, c.dy - r * 0.05);
  canvas.drawLine(waist, bottom, facet);
  canvas.drawLine(left, waist, facet);
  canvas.drawLine(right, waist, facet);
}

void _paintTarget(Canvas canvas, Offset c, double r, Color color) {
  canvas.drawCircle(
    c,
    r * 0.42,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.09,
  );
  canvas.drawCircle(
    c,
    r * 0.24,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.09,
  );
  canvas.drawCircle(c, r * 0.08, Paint()..color = color);
}

void _paintTrophy(Canvas canvas, Offset c, double r, Color color) {
  final fill = Paint()..color = color;
  final cupPath = Path()
    ..moveTo(c.dx - r * 0.28, c.dy - r * 0.35)
    ..lineTo(c.dx + r * 0.28, c.dy - r * 0.35)
    ..quadraticBezierTo(c.dx + r * 0.28, c.dy + r * 0.05, c.dx, c.dy + r * 0.08)
    ..quadraticBezierTo(c.dx - r * 0.28, c.dy + r * 0.05, c.dx - r * 0.28, c.dy - r * 0.35)
    ..close();
  canvas.drawPath(cupPath, fill);

  final handleStroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = r * 0.07;
  canvas.drawArc(
    Rect.fromCenter(center: Offset(c.dx - r * 0.3, c.dy - r * 0.18), width: r * 0.22, height: r * 0.3),
    -pi / 2,
    pi,
    false,
    handleStroke,
  );
  canvas.drawArc(
    Rect.fromCenter(center: Offset(c.dx + r * 0.3, c.dy - r * 0.18), width: r * 0.22, height: r * 0.3),
    pi / 2,
    pi,
    false,
    handleStroke,
  );

  canvas.drawRect(
    Rect.fromCenter(center: Offset(c.dx, c.dy + r * 0.22), width: r * 0.12, height: r * 0.2),
    fill,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(c.dx, c.dy + r * 0.38), width: r * 0.5, height: r * 0.12),
      Radius.circular(r * 0.04),
    ),
    fill,
  );
}

void _paintDove(Canvas canvas, Offset c, double r, Color color) {
  final fill = Paint()..color = color;
  final body = Path()
    ..moveTo(c.dx - r * 0.4, c.dy + r * 0.08)
    ..quadraticBezierTo(c.dx - r * 0.1, c.dy - r * 0.32, c.dx + r * 0.36, c.dy - r * 0.16)
    ..quadraticBezierTo(c.dx + r * 0.16, c.dy - r * 0.04, c.dx + r * 0.3, c.dy + r * 0.16)
    ..quadraticBezierTo(c.dx, c.dy + r * 0.12, c.dx - r * 0.4, c.dy + r * 0.08)
    ..close();
  canvas.drawPath(body, fill);
  canvas.drawCircle(Offset(c.dx + r * 0.34, c.dy - r * 0.19), r * 0.07, fill);
}

void _paintShield(Canvas canvas, Offset c, double r, Color color) {
  final fill = Paint()..color = color;
  final shieldPath = Path()
    ..moveTo(c.dx, c.dy - r * 0.42)
    ..lineTo(c.dx + r * 0.32, c.dy - r * 0.26)
    ..lineTo(c.dx + r * 0.32, c.dy + r * 0.08)
    ..quadraticBezierTo(c.dx + r * 0.3, c.dy + r * 0.35, c.dx, c.dy + r * 0.46)
    ..quadraticBezierTo(c.dx - r * 0.3, c.dy + r * 0.35, c.dx - r * 0.32, c.dy + r * 0.08)
    ..lineTo(c.dx - r * 0.32, c.dy - r * 0.26)
    ..close();
  canvas.drawPath(shieldPath, fill);
  canvas.drawLine(
    Offset(c.dx, c.dy - r * 0.38),
    Offset(c.dx, c.dy + r * 0.4),
    Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..strokeWidth = r * 0.04,
  );
}

void _paintScaleCoin(Canvas canvas, Offset c, double r, Color color) {
  final stroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = r * 0.1
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  canvas.drawPath(
    Path()
      ..moveTo(c.dx - r * 0.32, c.dy + r * 0.25)
      ..lineTo(c.dx - r * 0.05, c.dy - r * 0.05)
      ..lineTo(c.dx + r * 0.12, c.dy + r * 0.1)
      ..lineTo(c.dx + r * 0.35, c.dy - r * 0.3),
    stroke,
  );
  canvas.drawPath(
    Path()
      ..moveTo(c.dx + r * 0.35, c.dy - r * 0.3)
      ..lineTo(c.dx + r * 0.14, c.dy - r * 0.28)
      ..moveTo(c.dx + r * 0.35, c.dy - r * 0.3)
      ..lineTo(c.dx + r * 0.33, c.dy - r * 0.09),
    stroke,
  );
}
