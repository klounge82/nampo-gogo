import 'package:flutter/material.dart';

class LineChartWidget extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const LineChartWidget({
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
          painter: _LineChartPainter(values: values, labels: labels),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;

  _LineChartPainter({required this.values, required this.labels});

  @override
  void paint(Canvas canvas, Size size) {
    final double maxVal = values.reduce((a, b) => a > b ? a : b);
    final double minVal = values.reduce((a, b) => a < b ? a : b);
    final double range = maxVal - minVal == 0 ? 1.0 : maxVal - minVal;

    final double paddingLeft = 45.0;
    final double paddingRight = 15.0;
    final double paddingTop = 20.0;
    final double paddingBottom = 30.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    final Paint gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1.0;

    // Draw horizontal grid lines (3 divisions)
    for (int i = 0; i <= 3; i++) {
      final double y = paddingTop + (chartHeight / 3) * i;
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      // Draw Y label text
      final double valueLabel = maxVal - ((range / 3) * i);
      final String formattedLabel = valueLabel >= 1000000
          ? '${(valueLabel / 1000000).toStringAsFixed(1)}M'
          : valueLabel >= 1000
          ? '${(valueLabel / 1000).toStringAsFixed(0)}K'
          : valueLabel.toStringAsFixed(0);

      final TextPainter tp = TextPainter(
        text: TextSpan(
          text: formattedLabel,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 9.0),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(5.0, y - 6.0));
    }

    // Points calculation
    final double xStep =
        chartWidth / (values.length - 1 == 0 ? 1 : values.length - 1);
    final List<Offset> points = [];
    for (int i = 0; i < values.length; i++) {
      final double x = paddingLeft + i * xStep;
      final double ratio = range == 0 ? 0.5 : (values[i] - minVal) / range;
      final double y = paddingTop + chartHeight * (1.0 - ratio);
      points.add(Offset(x, y));
    }

    // Draw area under curve (Gradient Fill)
    final Path areaPath = Path()..moveTo(paddingLeft, paddingTop + chartHeight);
    for (int i = 0; i < points.length; i++) {
      areaPath.lineTo(points[i].dx, points[i].dy);
    }
    areaPath.lineTo(points.last.dx, paddingTop + chartHeight);
    areaPath.close();

    final Paint fillPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.withAlpha(80), Colors.blue.withAlpha(0)],
          ).createShader(
            Rect.fromLTWH(paddingLeft, paddingTop, chartWidth, chartHeight),
          );

    canvas.drawPath(areaPath, fillPaint);

    // Draw Smooth Line
    final Path linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final Paint linePaint = Paint()
      ..color = Colors.blue.shade600
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    // Draw points & label text on X axis
    for (int i = 0; i < points.length; i++) {
      // Draw indicator dot
      final Paint dotPaint = Paint()..color = Colors.blue.shade800;
      canvas.drawCircle(points[i], 4.0, dotPaint);
      canvas.drawCircle(points[i], 2.0, Paint()..color = Colors.white);

      // Draw X label text
      final TextPainter labelTp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(color: Colors.grey, fontSize: 9.0),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelTp.paint(
        canvas,
        Offset(
          points[i].dx - (labelTp.width / 2),
          size.height - paddingBottom + 8.0,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
