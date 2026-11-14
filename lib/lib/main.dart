import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const PrayerTrackerApp());
}

class PrayerTrackerApp extends StatelessWidget {
  const PrayerTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'নামাজ ট্র্যাকার',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const PrayerTrackerScreen(),
    );
  }
}

const List<String> prayers = ['ফজর', 'যোহর', 'আসর', 'মাগরিব', 'এশা'];

const List<String> monthNames = [
  'জানুয়ারি',
  'ফেব্রুয়ারি',
  'মার্চ',
  'এপ্রিল',
  'মে',
  'জুন',
  'জুলাই',
  'আগস্ট',
  'সেপ্টেম্বর',
  'অক্টোবর',
  'নভেম্বর',
  'ডিসেম্বর',
];

String bn(int n) {
  const digits = '০১২৩৪৫৬৭৮৯';
  return n.toString().split('').map((c) => digits[int.parse(c)]).join();
}

class PrayerTrackerScreen extends StatefulWidget {
  const PrayerTrackerScreen({super.key});

  @override
  State<PrayerTrackerScreen> createState() => _PrayerTrackerScreenState();
}

class _PrayerTrackerScreenState extends State<PrayerTrackerScreen> {
  final DateTime now = DateTime.now();
  late int year;
  late int month;
  SharedPreferences? prefs;
  List<List<bool>> tracker = [];

  String get _key => 'namaz-$year-$month';

  @override
  void initState() {
    super.initState();
    year = now.year;
    month = now.month;
    _init();
  }

  Future<void> _init() async {
    prefs = await SharedPreferences.getInstance();
    _load();
  }

  void _load() {
    final days = DateUtils.getDaysInMonth(year, month);
    final saved = prefs?.getString(_key) ?? '';
    setState(() {
      tracker = List.generate(days, (d) {
        return List.generate(prayers.length, (p) {
          final i = d * prayers.length + p;
          return i < saved.length && saved[i] == '1';
        });
      });
    });
  }

  void _save() {
    final text = tracker.expand((row) => row).map((b) => b ? '1' : '0').join();
    prefs?.setString(_key, text);
  }

  void _toggle(int day, int prayer) {
    setState(() {
      tracker[day][prayer] = !tracker[day][prayer];
    });
    _save();
  }

  void _changeMonth(int delta) {
    var m = month + delta;
    var y = year;
    if (m < 1) {
      m = 12;
      y--;
    }
    if (m > 12) {
      m = 1;
      y++;
    }
    year = y;
    month = m;
    _load();
  }

  bool _isToday(int day) {
    return year == now.year && month == now.month && day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = tracker.length * prayers.length;
    final done = tracker.fold<int>(0, (s, r) => s + r.where((b) => b).length);
    final fullDays = tracker.where((r) => r.every((b) => b)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('নামাজ ট্র্যাকার'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeMonth(-1),
              ),
              Text(
                '${monthNames[month - 1]} ${bn(year)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeMonth(1),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                Text(
                  'আদায়: ${bn(done)} / ${bn(total)}   |   পুরো ৫ ওয়াক্তের দিন: ${bn(fullDays)}',
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            color: cs.primaryContainer,
            child: Row(
              children: [
                _cell('তারিখ', width: 56, bold: true),
                ...prayers.map((p) => Expanded(child: _cell(p, bold: true))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tracker.length,
              itemBuilder: (context, day) {
                return Container(
                  color: _isToday(day + 1) ? Colors.amber.withOpacity(0.25) : null,
                  child: Row(
                    children: [
                      _cell(bn(day + 1), width: 56),
                      ...List.generate(prayers.length, (p) {
                        final on = tracker[day][p];
                        return Expanded(
                          child: InkWell(
                            onTap: () => _toggle(day, p),
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                              child: Icon(
                                on ? Icons.check_box : Icons.check_box_outline_blank,
                                color: on ? Colors.green : Colors.grey,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, {double? width, bool bold = false}) {
    return Container(
      width: width,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        text,
        style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
    );
  }
}
