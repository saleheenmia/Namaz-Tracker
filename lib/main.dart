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

const List<String> columns = ['ফজর', 'যোহর', 'আসর', 'মাগরিব', 'এশা', 'রোজা'];
const int prayerCount = 5;

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

const List<String> hijriMonths = [
  'মুহাররম',
  'সফর',
  'রবিউল আউয়াল',
  'রবিউস সানি',
  'জমাদিউল আউয়াল',
  'জমাদিউস সানি',
  'রজব',
  'শাবান',
  'রমজান',
  'শাওয়াল',
  'জিলকদ',
  'জিলহজ',
];

String bn(int n) {
  const digits = '০১২৩৪৫৬৭৮৯';
  return n.toString().split('').map((c) => digits[int.parse(c)]).join();
}

// গ্রেগরিয়ান তারিখ থেকে আনুমানিক হিজরি তারিখ: [বছর, মাস, দিন]
List<int> toHijri(DateTime date) {
  final a = (14 - date.month) ~/ 12;
  final y = date.year + 4800 - a;
  final m = date.month + 12 * a - 3;
  final jd = date.day +
      (153 * m + 2) ~/ 5 +
      365 * y +
      y ~/ 4 -
      y ~/ 100 +
      y ~/ 400 -
      32045;
  var l = jd - 1948440 + 10632;
  final n = (l - 1) ~/ 10631;
  l = l - 10631 * n + 354;
  final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
      (l ~/ 5670) * ((43 * l) ~/ 15238);
  l = l -
      ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
      (j ~/ 16) * ((15238 * j) ~/ 43) +
      29;
  final hm = (24 * l) ~/ 709;
  final hd = l - (709 * hm) ~/ 24;
  final hy = 30 * n + j - 30;
  return [hy, hm, hd];
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
  int qaza = 0;

  String get _key => 'namaz2-$year-$month';

  @override
  void initState() {
    super.initState();
    year = now.year;
    month = now.month;
    _init();
  }

  Future<void> _init() async {
    prefs = await SharedPreferences.getInstance();
    qaza = prefs?.getInt('qaza') ?? 0;
    _load();
  }

  void _load() {
    final days = DateUtils.getDaysInMonth(year, month);
    final saved = prefs?.getString(_key) ?? '';
    setState(() {
      tracker = List.generate(days, (d) {
        return List.generate(columns.length, (p) {
          final i = d * columns.length + p;
          return i < saved.length && saved[i] == '1';
        });
      });
    });
  }

  void _save() {
    final text = tracker.expand((row) => row).map((b) => b ? '1' : '0').join();
    prefs?.setString(_key, text);
  }

  void _toggle(int day, int col) {
    setState(() {
      tracker[day][col] = !tracker[day][col];
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

  void _changeQaza(int delta) {
    setState(() {
      qaza = qaza + delta;
      if (qaza < 0) qaza = 0;
    });
    prefs?.setInt('qaza', qaza);
  }

  bool _isToday(int day) {
    return year == now.year && month == now.month && day == now.day;
  }

  String _hijriToday() {
    final h = toHijri(now);
    return '${bn(h[2])} ${hijriMonths[h[1] - 1]} ${bn(h[0])} হিজরি';
  }

  void _showReport() {
    final days = tracker.length;
    final fullDays =
        tracker.where((r) => r.take(prayerCount).every((b) => b)).length;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${monthNames[month - 1]} ${bn(year)} এর রিপোর্ট',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...List.generate(columns.length, (p) {
                final c = tracker.where((r) => r[p]).length;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(width: 70, child: Text(columns[p])),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: days == 0 ? 0 : c / days,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${bn(c)}/${bn(days)}'),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 10),
              Text('পুরো ৫ ওয়াক্তের দিন: ${bn(fullDays)}'),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = tracker.length * prayerCount;
    final done = tracker.fold<int>(
        0, (s, r) => s + r.take(prayerCount).where((b) => b).length);
    final fullDays =
        tracker.where((r) => r.take(prayerCount).every((b) => b)).length;
    final fasts = tracker.where((r) => r[prayerCount]).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('নামাজ ট্র্যাকার'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'মাসের রিপোর্ট',
            onPressed: _showReport,
          ),
        ],
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
          Text(
            'আজ: ${_hijriToday()} (আনুমানিক)',
            style: TextStyle(fontSize: 13, color: cs.primary),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                Text(
                  'আদায়: ${bn(done)} / ${bn(total)}  |  পুরো ৫ ওয়াক্ত: ${bn(fullDays)} দিন  |  রোজা: ${bn(fasts)}',
                  style: const TextStyle(fontSize: 13),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('কাজা নামাজ বাকি: ${bn(qaza)}'),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: qaza > 0 ? () => _changeQaza(-1) : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => _changeQaza(1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: cs.primaryContainer,
            child: Row(
              children: [
                _cell('তারিখ', width: 52, bold: true),
                ...columns.map((c) => Expanded(child: _cell(c, bold: true))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tracker.length,
              itemBuilder: (context, day) {
                return Container(
                  color: _isToday(day + 1)
                      ? Colors.amber.withOpacity(0.25)
                      : null,
                  child: Row(
                    children: [
                      _cell(bn(day + 1), width: 52),
                      ...List.generate(columns.length, (p) {
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
                                on
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
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
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
