import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ReportApp());
}

class ReportApp extends StatelessWidget {
  const ReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ব্যক্তিগত রিপোর্ট',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const ReportScreen(),
    );
  }
}

class Col {
  final String title;
  final String unit;
  final bool check;
  final int max;
  final double width;
  const Col(this.title, this.unit, this.check, this.max, this.width);
}

const List<Col> cols = [
  Col('কুরআন অধ্যয়ন', '(✓)', true, 1, 76),
  Col('হাদিস অধ্যয়ন', '(সংখ্যা)', false, 999, 76),
  Col('ইসলামী সাহিত্য', '(পৃষ্ঠা)', false, 9999, 80),
  Col('জামায়াতে নামাজ', '(ওয়াক্ত)', false, 5, 82),
  Col('দাওয়াতি সাক্ষাৎ', '(কতবার)', false, 99, 82),
  Col('কর্মী সাক্ষাৎ', '(কতবার)', false, 99, 76),
  Col('কর্মী যোগাযোগ', '(কতবার)', false, 99, 82),
  Col('বই বিলি', '(কতটি)', false, 999, 66),
  Col('সামাজিক কাজ', '(✓)', true, 1, 76),
  Col('রিপোর্ট রাখা', '(✓)', true, 1, 76),
  Col('আত্মসমালোচনা', '(✓)', true, 1, 82),
];

const double dateW = 48;
const double commentW = 150;
const double rowH = 46;

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

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final DateTime now = DateTime.now();
  late int year;
  late int month;
  SharedPreferences? prefs;

  int tab = 0;
  List<List<int>> vals = [];
  List<String> comments = [];
  List<List<String>> targets = [];
  String yeanat = '';
  String note = '';

  String get _key => 'report-$year-$month';

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
    final v = List.generate(days, (_) => List.filled(cols.length, 0));
    final c = List.filled(days, '');
    final t = List.generate(9, (_) => ['', '', '']);
    var y = '';
    var n = '';
    final s = prefs?.getString(_key);
    if (s != null) {
      try {
        final m = jsonDecode(s) as Map<String, dynamic>;
        final sv = m['v'] as List;
        for (var d = 0; d < days && d < sv.length; d++) {
          final row = sv[d] as List;
          for (var i = 0; i < cols.length && i < row.length; i++) {
            v[d][i] = row[i] as int;
          }
        }
        final sc = m['c'] as List;
        for (var d = 0; d < days && d < sc.length; d++) {
          c[d] = sc[d] as String;
        }
        final st = m['t'] as List;
        for (var i = 0; i < 9 && i < st.length; i++) {
          final row = st[i] as List;
          for (var j = 0; j < 3 && j < row.length; j++) {
            t[i][j] = row[j] as String;
          }
        }
        y = (m['y'] ?? '') as String;
        n = (m['n'] ?? '') as String;
      } catch (_) {}
    }
    setState(() {
      vals = v;
      comments = c;
      targets = t;
      yeanat = y;
      note = n;
    });
  }

  void _save() {
    prefs?.setString(
      _key,
      jsonEncode({
        'v': vals,
        'c': comments,
        't': targets,
        'y': yeanat,
        'n': note,
      }),
    );
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

  Future<String?> _askText(String title, String initial) async {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
  }

  Future<void> _editNumber(int day, int c) async {
    final col = cols[c];
    var v = vals[day][c];
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('${bn(day + 1)} তারিখ: ${col.title} ${col.unit}'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 36),
                onPressed: v > 0 ? () => setD(() => v--) : null,
              ),
              SizedBox(
                width: 80,
                child: Center(
                  child: Text(
                    bn(v),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 36),
                onPressed: v < col.max ? () => setD(() => v++) : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('বাতিল'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, v),
              child: const Text('ঠিক আছে'),
            ),
          ],
        ),
      ),
    );
    if (result != null) {
      setState(() {
        vals[day][c] = result;
      });
      _save();
    }
  }

  Future<void> _editComment(int day) async {
    final r = await _askText('${bn(day + 1)} তারিখের মন্তব্য', comments[day]);
    if (r != null) {
      setState(() {
        comments[day] = r;
      });
      _save();
    }
  }

  Future<void> _editYeanat() async {
    final r = await _askText('মাসিক ইয়ানত আদায় (টাকা, তারিখ)', yeanat);
    if (r != null) {
      setState(() {
        yeanat = r;
      });
      _save();
    }
  }

  Future<void> _editNote() async {
    final r = await _askText('দায়িত্বশীলের মন্তব্য', note);
    if (r != null) {
      setState(() {
        note = r;
      });
      _save();
    }
  }

  Future<void> _editTarget(int i) async {
    final nameC = TextEditingController(text: targets[i][0]);
    final d1C = TextEditingController(text: targets[i][1]);
    final d2C = TextEditingController(text: targets[i][2]);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(i < 5 ? 'দাওয়াতি টার্গেট ${bn(i + 1)}' : 'কর্মী টার্গেট ${bn(i - 4)}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'নাম'),
              ),
              TextField(
                controller: d1C,
                decoration:
                    const InputDecoration(labelText: 'টার্গেটভুক্তকরণের তারিখ'),
              ),
              TextField(
                controller: d2C,
                decoration:
                    const InputDecoration(labelText: 'যোগাযোগের তারিখ'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ঠিক আছে'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        targets[i] = [nameC.text, d1C.text, d2C.text];
      });
      _save();
    }
  }

  Widget _box(
    Widget child,
    double w, {
    Color? color,
    VoidCallback? onTap,
    double h = rowH,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: w,
        height: h,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: child,
      ),
    );
  }

  Widget _monthNav() {
    return Row(
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
    );
  }

  Widget _headerRow(ColorScheme cs) {
    const double h = 64;
    return Row(
      children: [
        _box(const Text('তারিখ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            dateW, color: cs.primaryContainer, h: h),
        ...cols.map(
          (c) => _box(
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  c.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
                Text(c.unit, style: const TextStyle(fontSize: 10)),
              ],
            ),
            c.width,
            color: cs.primaryContainer,
            h: h,
          ),
        ),
        _box(const Text('মন্তব্য', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            commentW, color: cs.primaryContainer, h: h),
      ],
    );
  }

  Widget _dayRow(int d) {
    return Container(
      color: _isToday(d + 1) ? Colors.amber.withOpacity(0.25) : null,
      child: Row(
        children: [
          _box(Text(bn(d + 1)), dateW),
          ...List.generate(cols.length, (c) {
            final col = cols[c];
            final v = vals[d][c];
            if (col.check) {
              return _box(
                Icon(
                  v == 1 ? Icons.check_box : Icons.check_box_outline_blank,
                  color: v == 1 ? Colors.green : Colors.grey,
                ),
                col.width,
                onTap: () {
                  setState(() {
                    vals[d][c] = v == 1 ? 0 : 1;
                  });
                  _save();
                },
              );
            }
            return _box(
              Text(
                v > 0 ? bn(v) : '',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              col.width,
              color: v > 0 ? Colors.green.withOpacity(0.10) : null,
              onTap: () => _editNumber(d, c),
            );
          }),
          _box(
            Text(
              comments[d],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            commentW,
            onTap: () => _editComment(d),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(ColorScheme cs) {
    return Row(
      children: [
        _box(const Text('মোট', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            dateW, color: cs.secondaryContainer),
        ...List.generate(cols.length, (c) {
          final sum = vals.fold<int>(0, (s, r) => s + r[c]);
          return _box(
            Text(bn(sum), style: const TextStyle(fontWeight: FontWeight.bold)),
            cols[c].width,
            color: cs.secondaryContainer,
          );
        }),
        _box(const Text(''), commentW, color: cs.secondaryContainer),
      ],
    );
  }

  Widget _dailyView() {
    final cs = Theme.of(context).colorScheme;
    double totalW = dateW + commentW;
    for (final c in cols) {
      totalW += c.width;
    }
    return Column(
      children: [
        _monthNav(),
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, bc) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: totalW,
                height: bc.maxHeight,
                child: Column(
                  children: [
                    _headerRow(cs),
                    Expanded(
                      child: ListView.builder(
                        itemCount: vals.length,
                        itemBuilder: (context, d) => _dayRow(d),
                      ),
                    ),
                    _totalRow(cs),
                  ],
                ),
              ),
            ),
          ),
        ),
        InkWell(
          onTap: _editYeanat,
          child: Container(
            width: double.infinity,
            color: cs.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'মাসিক ইয়ানত আদায়: ${yeanat.isEmpty ? 'ট্যাপ করে লিখুন' : yeanat}',
                  ),
                ),
                const Icon(Icons.edit, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
      child: Text(
        t,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _targetTile(int i) {
    final t = targets[i];
    final no = i < 5 ? i + 1 : i - 4;
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(bn(no))),
        title: Text(t[0].isEmpty ? 'নাম লিখুন' : t[0]),
        subtitle: Text('ভুক্তকরণ: ${t[1]}   |   যোগাযোগ: ${t[2]}'),
        trailing: const Icon(Icons.edit, size: 18),
        onTap: () => _editTarget(i),
      ),
    );
  }

  Widget _targetsView() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _monthNav(),
        _sectionTitle('দাওয়াতি টার্গেট'),
        ...List.generate(5, (i) => _targetTile(i)),
        _sectionTitle('কর্মী টার্গেট'),
        ...List.generate(4, (i) => _targetTile(5 + i)),
        _sectionTitle('দায়িত্বশীলের মন্তব্য'),
        Card(
          child: ListTile(
            title: Text(note.isEmpty ? 'ট্যাপ করে লিখুন' : note),
            trailing: const Icon(Icons.edit, size: 18),
            onTap: _editNote,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ব্যক্তিগত রিপোর্ট'),
        centerTitle: true,
      ),
      body: vals.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : (tab == 0 ? _dailyView() : _targetsView()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.table_chart_outlined),
            selectedIcon: Icon(Icons.table_chart),
            label: 'দৈনিক রিপোর্ট',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'টার্গেট ও নোট',
          ),
        ],
      ),
    );
  }
}
