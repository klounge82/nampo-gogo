import 'package:flutter/material.dart';

class BarChartWidget extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const BarChartWidget({
    super.key,
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Center(child: Text('표시할 통계 데이터가 없습니다.'));
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: AspectRatio(
        aspectRatio: 1.7,
        child: CustomPaint(
          painter: _BarChartPainter(values: values, labels: labels),
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  _BarChartPainter({required this.values, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final double maxVal = values.reduce((a, b) => a > b ? a : b);
    final double range = maxVal == 0 ? 1.0 : maxVal;

    final double paddingLeft = 40.0;
    final double paddingRight = 10.0;
    final double paddingTop = 20.0;
    final double paddingBottom = 30.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    final Paint gridPaint = Paint()
      ..color = Colors.grey.shade100
      ..strokeWidth = 1.0;

    // Draw grid guide lines
    for (int i = 0; i <= 3; i++) {
      final double y = paddingTop + (chartHeight / 3) * i;
      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      // Y value label
      final double valueLabel = maxVal - ((range / 3) * i);
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: valueLabel.toStringAsFixed(0),
          style: TextStyle(color: Colors.grey.shade500, fontSize: 9.0),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(5.0, y - 6.0));
    }

    final double barGap = 12.0;
    final double totalBarsWidth = chartWidth - (barGap * (values.length - 1));
    final double barWidth = totalBarsWidth / values.length;

    for (int i = 0; i < values.length; i++) {
      final double barHeight = chartHeight * (values[i] / range);
      final double x = paddingLeft + (i * (barWidth + barGap));
      final double y = paddingTop + chartHeight - barHeight;

      final Rect barRect = Rect.fromLTWH(x, y, barWidth, barHeight);
      final RRect roundedBar = RRect.fromRectAndCorners(
        barRect,
        topLeft: const Radius.circular(6.0),
        topRight: const Radius.circular(6.0),
      );

      final Paint barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.orange.shade400, Colors.orange.shade700],
        ).createShader(barRect);

      canvas.drawRRect(roundedBar, barPaint);

      // Value label on top of bar
      final TextPainter valTp = TextPainter(
        text: TextSpan(
          text: values[i].toStringAsFixed(0),
          style: TextStyle(color: Colors.orange.shade900, fontSize: 8.5, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      valTp.paint(canvas, Offset(x + (barWidth / 2) - (valTp.width / 2), y - 14.0));

      // X label
      final TextPainter xTp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(color: Colors.grey, fontSize: 9.0),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      xTp.paint(canvas, Offset(x + (barWidth / 2) - (xTp.width / 2), size.height - paddingBottom + 8.0));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
