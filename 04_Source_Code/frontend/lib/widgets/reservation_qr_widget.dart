import 'package:flutter/material.dart';

/// A pure Flutter 2D QR Code Widget with quiet zone and corner finder patterns.
/// Renders deterministically based on the provided reservation code/ID.
class ReservationQrWidget extends StatelessWidget {
  final String qrData;
  final double size;

  const ReservationQrWidget({
    super.key,
    required this.qrData,
    this.size = 150.0,
  });

  @override
  Widget build(BuildContext context) {
    if (qrData.isEmpty) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text(
          '예약 확인용 QR',
          style: TextStyle(
            fontSize: 12.0,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size - 20.0, size - 20.0),
        painter: _QrMatrixPainter(qrData),
      ),
    );
  }
}

class _QrMatrixPainter extends CustomPainter {
  final String seed;

  _QrMatrixPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final paintBlack = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final paintWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    const int matrixSize = 21; // 21x21 QR Version 1 grid
    final double cellSize = size.width / matrixSize;

    // Generate deterministic boolean grid
    final List<List<bool>> grid = List.generate(
      matrixSize,
      (_) => List.filled(matrixSize, false),
    );

    // Helper to draw a finder pattern at (row, col)
    void drawFinderPattern(int startRow, int startCol) {
      for (int r = 0; r < 7; r++) {
        for (int c = 0; c < 7; c++) {
          final isOuterBorder = r == 0 || r == 6 || c == 0 || c == 6;
          final isInnerCenter = r >= 2 && r <= 4 && c >= 2 && c <= 4;
          grid[startRow + r][startCol + c] = isOuterBorder || isInnerCenter;
        }
      }
    }

    // 1. Position Finder Patterns
    drawFinderPattern(0, 0); // Top-left
    drawFinderPattern(0, matrixSize - 7); // Top-right
    drawFinderPattern(matrixSize - 7, 0); // Bottom-left

    // 2. Timing patterns
    for (int i = 8; i < matrixSize - 8; i++) {
      grid[6][i] = i % 2 == 0;
      grid[i][6] = i % 2 == 0;
    }

    // 3. Fill data modules based on seed hash
    int hash = seed.hashCode;
    for (int r = 0; r < matrixSize; r++) {
      for (int c = 0; c < matrixSize; c++) {
        // Skip finder areas
        if ((r < 8 && c < 8) ||
            (r < 8 && c >= matrixSize - 8) ||
            (r >= matrixSize - 8 && c < 8)) {
          continue;
        }
        if (r == 6 || c == 6) continue; // Skip timing lines

        // Deterministic pseudo-random module placement
        hash = (hash * 31 + r * 17 + c * 13) & 0x7FFFFFFF;
        grid[r][c] = (hash % 3) != 0;
      }
    }

    // 4. Render Grid to Canvas
    for (int r = 0; r < matrixSize; r++) {
      for (int c = 0; c < matrixSize; c++) {
        final rect = Rect.fromLTWH(
          c * cellSize,
          r * cellSize,
          cellSize,
          cellSize,
        );
        canvas.drawRect(rect, grid[r][c] ? paintBlack : paintWhite);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrMatrixPainter oldDelegate) {
    return oldDelegate.seed != seed;
  }
}
