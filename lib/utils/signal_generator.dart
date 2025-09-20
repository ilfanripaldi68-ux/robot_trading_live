// lib/utils/signal_generator.dart
import '../services/api_service.dart';

double sma(List<double> data, int period) {
  if (data.length < period) return 0;
  final sub = data.sublist(data.length - period);
  return sub.reduce((a, b) => a + b) / period;
}

double rsi(List<double> closes, {int period = 14}) {
  if (closes.length < period + 1) return 50;
  double gain = 0, loss = 0;
  for (int i = closes.length - period; i < closes.length; i++) {
    final diff = closes[i] - closes[i - 1];
    if (diff >= 0) gain += diff; else loss -= diff;
  }
  if (loss == 0) return 100;
  final rs = gain / loss;
  return 100 - (100 / (1 + rs));
}

double atr(List<Candle> candles, {int period = 14}) {
  if (candles.length < period + 1) return 0;
  List<double> trs = [];
  for (int i = candles.length - period; i < candles.length; i++) {
    final high = candles[i].high;
    final low = candles[i].low;
    final prevClose = candles[i - 1].close;
    final tr = [high - low, (high - prevClose).abs(), (low - prevClose).abs()].reduce((a, b) => a > b ? a : b);
    trs.add(tr);
  }
  return trs.reduce((a, b) => a + b) / trs.length;
}

String generateSignal(List<Candle> candles) {
  if (candles.length < 20) return "WAIT";
  final closes = candles.map((c) => c.close).toList();
  final sma5 = sma(closes, 5);
  final sma20 = sma(closes, 20);
  final r = rsi(closes);
  if (sma5 > sma20 && r < 70) return "BUY";
  if (sma5 < sma20 && r > 30) return "SELL";
  return "HOLD";
}
