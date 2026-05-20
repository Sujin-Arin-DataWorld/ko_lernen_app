import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/storage_service.dart';
import '../widgets/banner_ad.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero
              Row(
                children: [
                  SizedBox(
                    width: 56, height: 56,
                    child: SvgPicture.asset('assets/icons/icon.svg'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [Color(0xFFE64980), Color(0xFF845EF7), Color(0xFF339AF0)],
                          ).createShader(b),
                          child: Text(
                            t.appTitle,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.welcomeMsg,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bar_chart_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.pushNamed(context, '/stats'),
                    tooltip: t.sectionStats,
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: AppColors.textMuted),
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                    tooltip: t.settingsTitle,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Lernmodule ──
              _Section(t.sectionModules),
              _ModuleCard(
                title: '🎬  ${t.moduleScenariosTitle}',
                desc:  t.moduleScenariosDesc,
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(context, '/scenarios'),
              ),
              const SizedBox(height: 10),
              _ModuleCard(
                title: '🔤  ${t.moduleHangulTitle}',
                desc:  t.moduleHangulDesc,
                color: AppColors.hangul,
                onTap: () => Navigator.pushNamed(context, '/hangul'),
              ),
              const SizedBox(height: 10),
              _ModuleCard(
                title: '📚  ${t.moduleVocabTitle}',
                desc:  t.moduleVocabDesc,
                color: AppColors.vocab,
                onTap: () => Navigator.pushNamed(context, '/vocab'),
              ),
              const SizedBox(height: 10),
              _ModuleCard(
                title: '📝  ${t.moduleGrammarTitle}',
                desc:  t.moduleGrammarDesc,
                color: AppColors.grammar,
                onTap: () => Navigator.pushNamed(context, '/grammar'),
              ),
              const SizedBox(height: 10),
              _ModuleCard(
                title: '🎧  ${t.moduleListenTitle}',
                desc:  t.moduleListenDesc,
                color: AppColors.listen,
                onTap: () => Navigator.pushNamed(context, '/listening'),
              ),

              const SizedBox(height: 24),

              // ── Spiele ──
              _Section(t.sectionGames),
              _ModuleCard(
                title: '🔠  ${t.gameChosungTitle}',
                desc:  t.gameChosungDesc,
                color: AppColors.primary,
                onTap: () => Navigator.pushNamed(context, '/chosung'),
              ),
              const SizedBox(height: 10),
              _ModuleCard(
                title: '🟩  ${t.gameWordleTitle}',
                desc:  t.gameWordleDesc,
                color: AppColors.listen,
                onTap: () => Navigator.pushNamed(context, '/wordle'),
              ),

              const SizedBox(height: 24),
              if (Storage.adsEnabled) const Center(child: AppBannerAd()),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  t.footerCheer,
                  style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  const _Section(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.5),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String desc;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.desc,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.15),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.8), width: 1.5),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.18), color.withOpacity(0.05)],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color.lerp(color, AppColors.text, 0.25),
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withOpacity(0.75)),
            ],
          ),
        ),
      ),
    );
  }
}
