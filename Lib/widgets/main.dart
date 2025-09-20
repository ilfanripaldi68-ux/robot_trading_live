// lib/widgets/trading_chart.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CandlesPainter extends CustomPainter {
  final List<Candle> candles;
  CandlesPainter(this.candles);

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;
    final paint = Paint()..style = PaintingStyle.fill;
    final margin = 8.0;
    final w = size.width - margin * 2;
    final h = size.height - margin * 2;
    final maxPrice = candles.map((c) => c.high).reduce((a, b) => a > b ? a : b);
    final minPrice = candles.map((c) => c.low).reduce((a, b) => a < b ? a : b);
    final priceRange = (maxPrice - minPrice) == 0 ? 1 : (maxPrice - minPrice);
    final candleWidth = w / candles.length * 0.7;

    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final xCenter = margin + (i + 0.5) * (w / candles.length);
      double y(double price) {
        final p = (price - minPrice) / priceRange;
        return margin + (1 - p) * h;
      }
      final yHigh = y(c.high);
      final yLow = y(c.low);
      final yOpen = y(c.open);
      final yClose = y(c.close);
      final wickPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(xCenter, yHigh), Offset(xCenter, yLow), wickPaint);
      final bool bullish = c.close >= c.open;
      paint.color = bullish ? Colors.green : Colors.red;
      final rectTop = bullish ? yOpen : yClose;
      final rectBottom = bullish ? yClose : yOpen;
      final rect = Rect.fromLTRB(xCenter - candleWidth / 2, rectTop, xCenter + candleWidth / 2, rectBottom);
      canvas.drawRect(rect, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CandlestickChart extends StatelessWidget {
  final List<Candle> candles;
  const CandlestickChart({super.key, required this.candles});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CandlesPainter(candles),
      size: Size(double.infinity, 240),
    );
  }
}
