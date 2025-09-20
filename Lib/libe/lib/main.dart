// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/api_service.dart';
import 'widgets/trading_chart.dart';
import 'utils/signal_generator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final notifications = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await notifications.initialize(initSettings);
  runApp(MyApp(notifications: notifications));
}

class MyApp extends StatelessWidget {
  final FlutterLocalNotificationsPlugin notifications;
  const MyApp({super.key, required this.notifications});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Robot Trading Live',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(notifications: notifications),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final FlutterLocalNotificationsPlugin notifications;
  const HomeScreen({super.key, required this.notifications});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Candle> candles = [];
  String currentPair = "EUR/USD";
  Timer? timer;
  String signal = "WAIT";
  final List<String> pairs = ["EUR/USD", "BTC/USDT", "XAU/USD"];

  @override
  void initState() {
    super.initState();
    _loadData();
    timer = Timer.periodic(Duration(seconds: 60), (_) => _loadData());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final c = await ApiService.fetchCandles(currentPair.replaceAll("/", ""), "1min");
      setState(() => candles = c);
      final sig = generateSignal(candles);
      if (sig != signal) {
        signal = sig;
        final atrVal = atr(candles);
        final entry = candles.last.close;
        double tp = entry, sl = entry;
        if (sig == "BUY") { tp = entry + atrVal * 2; sl = entry - atrVal; }
        else if (sig == "SELL") { tp = entry - atrVal * 2; sl = entry + atrVal; }
        _notify(sig, entry, tp, sl);
      }
    } catch (e) { print("Error: $e"); }
  }

  Future<void> _notify(String sig, double entry, double tp, double sl) async {
    const androidDetails = AndroidNotificationDetails(
        'trading_channel', 'Trading Signals',
        importance: Importance.high, priority: Priority.high);
    const details = NotificationDetails(android: androidDetails);
    await widget.notifications.show(0, "Signal: $sig",
        "Entry: ${entry.toStringAsFixed(5)} TP: ${tp.toStringAsFixed(5)} SL: ${sl.toStringAsFixed(5)}",
        details);
  }

  @override
  Widget build(BuildContext context) {
    final entry = candles.isNotEmpty ? candles.last.close : 0;
    final atrVal = candles.isNotEmpty ? atr(candles) : 0;
    double tp = entry, sl = entry;
    if (signal == "BUY") { tp = entry + atrVal * 2; sl = entry - atrVal; }
    if (signal == "SELL") { tp = entry - atrVal * 2; sl = entry + atrVal; }

    return Scaffold(
      appBar: AppBar(title: Text("Robot Trading - Live Market")),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          DropdownButton<String>(
            value: currentPair,
            items: pairs.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) { if (v != null) { setState(() => currentPair = v); _loadData(); } },
          ),
          SizedBox(height: 12),
          Expanded(child: Card(child: Padding(padding: EdgeInsets.all(8), child:
            CandlestickChart(candles: candles)
          ))),
          SizedBox(height: 12),
          Card(child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Pair: $currentPair"),
              Text("Signal: $signal", style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold,
                color: signal=="BUY" ? Colors.green : signal=="SELL" ? Colors.red : Colors.black)),
              if (signal != "WAIT") Text("Entry: ${entry.toStringAsFixed(5)}"),
              if (signal != "WAIT") Text("TP: ${tp.toStringAsFixed(5)}"),
              if (signal != "WAIT") Text("SL: ${sl.toStringAsFixed(5)}"),
            ]),
          ))
        ]),
      ),
    );
  }
}
