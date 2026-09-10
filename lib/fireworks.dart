import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A transparent, non-interactive layer of rockets and fading sparks.
class Fireworks extends StatefulWidget {
  const Fireworks({super.key});

  @override
  State<Fireworks> createState() => FireworksState();
}

class FireworksState extends State<Fireworks>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final List<_Burst> _bursts = [];
  final _clock = ValueNotifier<double>(0);
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _clock.value = elapsed.inMicroseconds / 1000000;
      _bursts.removeWhere((burst) => _clock.value - burst.start > 2.3);
      if (_bursts.isEmpty) _ticker.stop();
    });
  }

  void launch(Offset target) {
    if (MediaQuery.disableAnimationsOf(context)) return;
    if (!_ticker.isActive) {
      _clock.value = 0;
      _ticker.start();
    }
    // Bound work even when the button is pressed rapidly.
    if (_bursts.length >= 12) _bursts.removeAt(0);
    _bursts.add(_Burst(target, _clock.value, _random.nextDouble() * 360));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(painter: _FireworksPainter(_bursts, _clock)),
    ),
  );
}

class _Burst {
  _Burst(this.target, this.start, this.hue);
  final Offset target;
  final double start;
  final double hue;
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter(this.bursts, this.clock) : super(repaint: clock);
  final List<_Burst> bursts;
  final ValueNotifier<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final paint = Paint()..strokeCap = StrokeCap.round;
    for (final burst in bursts) {
      final age = clock.value - burst.start;
      final target = Offset(
        burst.target.dx * size.width,
        burst.target.dy * size.height,
      );
      final origin = Offset(size.width - 44, size.height);
      final color = HSVColor.fromAHSV(1, burst.hue, 0.85, 0.85).toColor();
      if (age < 0.55) {
        final progress = Curves.easeOut.transform((age / 0.55).clamp(0.0, 1.0));
        final head = Offset.lerp(origin, target, progress)!;
        final tail = Offset.lerp(origin, target, max(0.0, progress - 0.12))!;
        paint
          ..color = color
          ..strokeWidth = 3;
        canvas.drawLine(tail, head, paint);
        canvas.drawCircle(head, 4, paint);
      } else {
        final t = (age - 0.55) / 1.75;
        if (t >= 1) continue;
        final radius = min(size.width, size.height) * 0.27;
        for (var i = 0; i < 48; i++) {
          final angle = i * pi * 2 / 48;
          final speed = radius * (0.55 + (i % 5) * 0.11);
          final distance = speed * (1 - pow(1 - t, 3));
          final direction = Offset(cos(angle), sin(angle));
          final point = target + direction * distance + Offset(0, 75 * t * t);
          final sparkColor = HSVColor.fromAHSV(
            (1 - t).clamp(0.0, 1.0),
            (burst.hue + i % 3 * 25) % 360,
            0.85,
            0.85,
          ).toColor();
          paint
            ..color = sparkColor
            ..strokeWidth = 2 * (1 - t) + 0.5;
          canvas.drawLine(point - direction * (8 * (1 - t)), point, paint);
          canvas.drawCircle(point, 2 * (1 - t) + 0.5, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_FireworksPainter oldDelegate) => true;
}
