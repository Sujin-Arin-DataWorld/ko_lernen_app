/// 임시 프리뷰 엔트리포인트 — 책가도 서재 + 두루마리 동작 확인용.
///
///     flutter run -t lib/main_shelf_preview.dart
///
/// 프로덕션 코드(`main.dart`·라우트)를 건드리지 않는다. 자산 없이 색면만으로
/// 상호작용을 먼저 확인하는 것이 목적이고, 판단이 끝나면 이 파일은 지운다.
library;

import 'package:flutter/material.dart';

import 'theme.dart';
import 'widgets/sori/chaekgado/scroll_sheet.dart';
import 'widgets/sori/chaekgado/shelf_case.dart';
import 'widgets/sori/toast.dart';
import 'widgets/sori/tokens.dart';

void main() => runApp(const _ShelfPreviewApp());

/// A1 18칸 — 이름표는 ARB 가 오기 전이라 하드코딩이다.
/// 개수는 실제 코퍼스 분포(a1 67편/18칸)를 흉내낸 값이다.
const _a1 = <ChaekgadoCompartment>[
  ChaekgadoCompartment(
    slug: 'transit',
    label: 'Bahn & Bus',
    count: 4,
    progress: .55,
  ),
  ChaekgadoCompartment(
    slug: 'taxi_stay',
    label: 'Taxi & Flughafen',
    count: 5,
    progress: .30,
  ),
  ChaekgadoCompartment(
    slug: 'counter',
    label: 'Läden & Schalter',
    count: 4,
    progress: .72,
  ),
  ChaekgadoCompartment(
    slug: 'eat',
    label: 'Café & Snack',
    count: 4,
    progress: .44,
  ),
  ChaekgadoCompartment(
    slug: 'home',
    label: 'Zuhause & Eingang',
    count: 3,
    progress: .18,
  ),
  ChaekgadoCompartment(
    slug: 'greet',
    label: 'Gruß & Termine',
    count: 4,
    progress: .90,
  ),
  ChaekgadoCompartment(
    slug: 'repeat',
    label: 'Nicht verstanden',
    count: 3,
    progress: .05,
  ),
  ChaekgadoCompartment(
    slug: 'body',
    label: 'Apotheke & Wetter',
    count: 4,
    progress: .36,
  ),
  ChaekgadoCompartment(
    slug: 'partner',
    label: 'Partnerfamilie',
    count: 3,
    progress: .12,
  ),
  ChaekgadoCompartment(
    slug: 'numbers',
    label: 'Zahlen & Uhrzeit',
    count: 4,
    progress: .60,
  ),
  ChaekgadoCompartment(
    slug: 'phone',
    label: 'Anrufe & Nachrichten',
    count: 3,
    progress: 0,
  ),
  ChaekgadoCompartment(
    slug: 'wayfinding',
    label: 'Wege & Schilder',
    count: 4,
    progress: .25,
  ),
];

/// C1 12칸 — **4칸만 재고가 있다.** 나머지는 count 0 이라 소품만 놓인다.
/// 이 화면이 "C1/C2 를 신규 아트 0장으로 출시한다"는 주장의 증거다.
const _c1 = <ChaekgadoCompartment>[
  ChaekgadoCompartment(
    slug: 'briefing',
    label: 'Briefing & Rederecht',
    count: 4,
    progress: .25,
  ),
  ChaekgadoCompartment(
    slug: 'uncertainty',
    label: 'Unsicherheit & Stichproben',
    count: 4,
    progress: 0,
  ),
  ChaekgadoCompartment(
    slug: 'access',
    label: 'Zugriff & Fristen',
    count: 1,
    progress: 0,
  ),
  ChaekgadoCompartment(
    slug: 'labor',
    label: 'Unsichtbare Arbeit',
    count: 2,
    progress: 0,
  ),
  ChaekgadoCompartment(slug: 'conflict_interest', label: 'Interessenkonflikt'),
  ChaekgadoCompartment(slug: 'policy', label: 'Auslegung & Ermessen'),
  ChaekgadoCompartment(slug: 'clinical', label: 'Aufklärung & Einwilligung'),
  ChaekgadoCompartment(slug: 'critique', label: 'Kultur- & Kunstkritik'),
  ChaekgadoCompartment(slug: 'mediation', label: 'Interkulturelle Vermittlung'),
  ChaekgadoCompartment(slug: 'methodology', label: 'Methodik'),
  ChaekgadoCompartment(slug: 'facework', label: 'Widerspruch'),
  ChaekgadoCompartment(slug: 'attribution', label: 'Zitieren & Quellen'),
];

/// 칸 → 시나리오. 두루마리 길이가 개수에 따라 달라지는 것을 보려고
/// 4편짜리와 1편짜리를 같이 둔다.
const _items = <String, List<(String, String, String, bool)>>{
  'eat': [
    ('Im Café bestellen', '주문하기', '1:30', true),
    ('Die Karte lesen', '메뉴 고르기', '2:10', true),
    ('Getrennt zahlen', '계산하기', '1:45', false),
    ('Snack zum Mitnehmen', '간식 사기', '1:20', false),
  ],
  'access': [('Fristen aushandeln', '기한 협의하기', '3:40', false)],
};

const _fallback = [
  ('Szenario A', '시나리오 하나', '2:00', false),
  ('Szenario B', '시나리오 둘', '1:40', false),
  ('Szenario C', '시나리오 셋', '2:20', false),
];

class _ShelfPreviewApp extends StatelessWidget {
  const _ShelfPreviewApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Chaekgado preview',
    theme: AppTheme.light,
    debugShowCheckedModeBanner: false,
    home: const _ShelfPreviewScreen(),
  );
}

class _ShelfPreviewScreen extends StatefulWidget {
  const _ShelfPreviewScreen();

  @override
  State<_ShelfPreviewScreen> createState() => _ShelfPreviewScreenState();
}

class _ShelfPreviewScreenState extends State<_ShelfPreviewScreen> {
  bool _showC1 = false;

  List<ChaekgadoCompartment> get _cells => _showC1 ? _c1 : _a1;

  Future<void> _open(ChaekgadoCompartment cell) async {
    final rows = _items[cell.slug] ?? _fallback.take(cell.count).toList();
    final picked = await showChaekgadoScroll<String>(
      context: context,
      title: cell.label,
      subtitle: cell.isStocked
          ? '${cell.count} Szenarien'
          : 'noch nicht bestückt',
      footnote: _showC1 ? 'C1 · Fach von 12' : 'A1 · Fach von 18',
      // 자산이 오면 여기에 `assets/illustrations/listening/{Key}.webp` 가 온다.
      illustration: const ColoredBox(color: SoriColors.lightSurfaceAlt),
      items: [
        for (var i = 0; i < rows.length; i++)
          ChaekgadoScrollItem(
            ordinal: '${i + 1}',
            title: rows[i].$1,
            subtitle: rows[i].$2,
            duration: rows[i].$3,
            done: rows[i].$4,
            onTap: () => Navigator.of(context).pop(rows[i].$1),
          ),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Spacing.lg),
            child: Center(
              child: Text(
                'Für dieses Fach gibt es noch keine Szenarien.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: SoriColors.lightTextMuted,
                ),
              ),
            ),
          ),
      ],
    );
    if (picked != null && mounted) {
      soriNotice(context, '→ player: $picked');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoriColors.lightBg,
      appBar: AppBar(
        title: const Text('Hören'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showC1 = !_showC1),
            child: Text(_showC1 ? 'A1 보기' : 'C1 보기'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 단청 띠 — 자산이 오면 이미지로 바꾼다.
          const SizedBox(height: 9, child: _DancheongBand()),
          Expanded(
            child: SingleChildScrollView(
              child: ChaekgadoShelfCase(
                compartments: _cells,
                emptyLabel: 'noch nicht bestückt',
                onOpen: _open,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DancheongBand extends StatelessWidget {
  const _DancheongBand();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        tileMode: TileMode.repeated,
        begin: Alignment.centerLeft,
        end: Alignment(-0.86, 0),
        colors: [
          Color(0xFF5F9A93),
          Color(0xFF5F9A93),
          Color(0xFF2F5F58),
          Color(0xFFB94B32),
          Color(0xFFDFA951),
          Color(0xFF2F5F58),
        ],
        stops: [0, 0.42, 0.54, 0.77, 0.88, 1],
      ),
    ),
    child: SizedBox.expand(),
  );
}
