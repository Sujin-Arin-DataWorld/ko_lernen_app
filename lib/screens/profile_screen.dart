import 'package:flutter/material.dart';

import '../widgets/sori/tokens.dart';
import '../widgets/sori/responsive.dart';
import '../widgets/sori/card.dart';
import '../widgets/sori/button.dart';
import '../widgets/sori/mascot.dart';
import '../widgets/sori/screen_coach.dart';
import '../widgets/sori/spotlight_coach.dart';
import '../services/auth_service.dart';
import '../services/account/account_transition_coordinator.dart';
import '../services/account/account_ui_operations.dart';
import '../services/storage_service.dart';
import '../data/learner_motivation.dart';
import '../widgets/sori/motivation_sheet.dart';
import '../widgets/sori/account_operation_ui.dart';
import '../l10n/generated/app_localizations.dart';

String _providerLabel(AppL10n t, AuthProviderState providers) {
  if (providers.isGoogleLinked && providers.isAppleLinked) {
    return t.authProviderGoogleAndApple;
  }
  if (providers.isAppleLinked) {
    return t.authProviderApple;
  }
  return t.authProviderGoogle;
}

/// **ProfileScreen** (`/profile`) — Identitäts- & Konto-Hub.
///
/// Duolingo-Muster: anonymer Start, aber das Konto ist *sichtbar* und lädt
/// aktiv zum Sichern ein (statt versteckt in den Einstellungen). Tiefen-
/// Statistik bleibt in [StatsScreen] (`/stats`); hier nur Identität,
/// Konto-Status und eine Kurz-Übersicht (Streak · Level · Vokabeln).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.account, this.accountOperations});

  final AuthAccountSnapshot? account;
  final AccountUiOperations? accountOperations;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with ScreenCoachMixin<ProfileScreen> {
  bool _busy = false;

  AccountUiOperations get _accountOperations =>
      widget.accountOperations ?? const ProductionAccountUiOperations();

  // ── 코치마크 타겟 ──
  final GlobalKey _accountCardKey = GlobalKey();

  @override
  String get coachId => 'profile';

  @override
  List<SpotlightStep> buildCoachSteps(BuildContext context) {
    final t = AppL10n.of(context);
    return [
      SpotlightStep(
        targetKey: _accountCardKey,
        title: t.coachProfileTitle,
        body: t.coachProfileBody,
        icon: Icons.cloud_upload_outlined,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    scheduleCoach();
  }

  Future<void> _connectWith(AccountLinkProvider provider) async {
    setState(() => _busy = true);
    try {
      await runConfirmedAccountLink(
        context,
        operations: _accountOperations,
        provider: provider,
        onCompleted: () async {
          if (mounted) setState(() {});
        },
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await AuthService.signOut();
    } catch (_) {
      // signOut bricht still ab, wenn Firebase nicht verfügbar ist.
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _changeMotivation() async {
    await showMotivationSheet(context);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    final account = widget.account ?? AuthService.accountSnapshot;
    final providers = account.providers;
    final linked = providers.isDurable;
    final providerLabel = _providerLabel(t, providers);
    final name = account.displayName;
    final photo = account.photoUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.profileTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: soriClampPadding(
            MediaQuery.sizeOf(context).width,
            base: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          ),
          children: [
            // ── Avatar + Name ──
            Center(
              child: _Avatar(linked: linked, photo: photo),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                linked ? (name ?? providerLabel) : t.profileGuestName,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: s.text,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                linked
                    ? t.profileConnectedProviderBadge(providerLabel)
                    : t.profileGuestBadge,
                style: TextStyle(fontSize: 13, color: s.textMuted),
              ),
            ),
            const SizedBox(height: 20),

            // ── Konto-Status ──
            AccountPendingOperationPanel(
              operations: _accountOperations,
              onCompleted: () async {
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 12),
            KeyedSubtree(
              key: _accountCardKey,
              child: AccountNewLinkGuard(
                operations: _accountOperations,
                builder: (context, linkAvailable) => linked
                    ? _ConnectedCard(
                        name: name ?? providerLabel,
                        onSignOut: _signOut,
                      )
                    : _GuestCard(
                        busy: _busy,
                        onConnect: linkAvailable
                            ? () => _connectWith(AccountLinkProvider.google)
                            : null,
                        onConnectApple:
                            linkAvailable &&
                                _accountOperations.appleSignInAvailable
                            ? () => _connectWith(AccountLinkProvider.apple)
                            : null,
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Kurz-Übersicht ──
            const _StatsRow(),
            const SizedBox(height: 16),
            // ── Lern-Motivation (왜 배우는가 — 정체성 강화) ──
            if (learnerMotivationFromId(Storage.motivation)
                case final mot?) ...[
              _MotivationCard(motivation: mot, onTap: _changeMotivation),
              const SizedBox(height: 16),
            ],
            SoriButton.outlined(
              label: t.profileViewStats,
              icon: Icons.bar_chart_rounded,
              fullWidth: true,
              onTap: () => Navigator.pushNamed(context, '/stats'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final bool linked;
  final String? photo;
  const _Avatar({required this.linked, required this.photo});

  static const double _d = 104;

  @override
  Widget build(BuildContext context) {
    final Widget inner = (linked && photo != null && photo!.isNotEmpty)
        ? Image.network(
            photo!,
            width: _d,
            height: _d,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _tigerInner(),
          )
        : _tigerInner();
    // 원형 메달리온 프레임 — 떠 있던 마스코트를 '의도된 초상'으로 감싼다.
    return Container(
      width: _d,
      height: _d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 0.95,
          colors: [
            SoriColors.lightSurface,
            SoriColors.tiger.withValues(alpha: 0.14),
          ],
        ),
        border: Border.all(
          color: SoriColors.tiger.withValues(alpha: 0.38),
          width: 2.5,
        ),
        boxShadow: SoriElevation.low,
      ),
      child: ClipOval(child: inner),
    );
  }

  Widget _tigerInner() => const Padding(
    padding: EdgeInsets.all(5),
    child: Mascot.tiger(
      size: _d - 10,
      emotion: MascotEmotion.smile,
      animate: true,
    ),
  );
}

/// Gast: lädt zum Sichern ein (der Kern-Nudge).
class _GuestCard extends StatelessWidget {
  final bool busy;
  final VoidCallback? onConnect;
  final VoidCallback? onConnectApple;
  const _GuestCard({
    required this.busy,
    required this.onConnect,
    this.onConnectApple,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.hero,
      tinted: true,
      accent: SoriColors.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: SoriColors.gold,
                size: 22,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  t.profileGuestBadge,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: s.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t.profileGuestDesc,
            style: TextStyle(fontSize: 13, height: 1.45, color: s.textMuted),
          ),
          const SizedBox(height: 8),
          Text(
            t.accountSafeConnectExplain,
            style: TextStyle(fontSize: 12.5, height: 1.4, color: s.textMuted),
          ),
          const SizedBox(height: 16),
          SoriButton.filled(
            label: t.settingsCloudSignInPrompt,
            icon: Icons.cloud_upload_outlined,
            fullWidth: true,
            onTap: busy ? null : onConnect,
          ),
          if (onConnectApple != null) ...[
            const SizedBox(height: 8),
            SoriButton.outlined(
              label: t.authAppleSignIn,
              icon: Icons.apple,
              fullWidth: true,
              onTap: busy ? null : onConnectApple,
            ),
          ],
        ],
      ),
    );
  }
}

/// Verbunden: zeigt Status + Abmelden.
class _ConnectedCard extends StatelessWidget {
  final String? name;
  final VoidCallback onSignOut;
  const _ConnectedCard({required this.name, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.hero,
      tinted: true,
      accent: SoriColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: SoriColors.primary,
                size: 22,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  t.settingsCloudSignedIn(name ?? 'Google'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: s.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t.profileConnectedDesc,
            style: TextStyle(fontSize: 13, height: 1.45, color: s.textMuted),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SoriButton.ghost(
              label: t.profileSignOut,
              icon: Icons.logout_rounded,
              onTap: onSignOut,
            ),
          ),
        ],
      ),
    );
  }
}

class _MotivationCard extends StatelessWidget {
  final LearnerMotivation motivation;
  final VoidCallback onTap;

  const _MotivationCard({required this.motivation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.base,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: motivation.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(SoriRadius.sm),
            ),
            alignment: Alignment.center,
            child: Icon(motivation.icon, color: motivation.accent, size: 22),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.motivationChangeLabel,
                  style: TextStyle(fontSize: 11.5, color: s.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  motivation.label(t),
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: s.text,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, color: s.textDim, size: 18),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.local_fire_department_rounded,
            value: '${Storage.streakDays}',
            label: t.profileStatStreak,
            color: SoriColors.tiger,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.star_rounded,
            value: '${Storage.xpLevel}',
            label: t.profileStatLevel,
            color: SoriColors.gold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            icon: Icons.menu_book_rounded,
            value: '${Storage.vokCorrect}',
            label: t.profileStatWords,
            color: SoriColors.primary,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final s = SoriSurfaces.of(context);
    return SoriCard(
      variant: SoriCardVariant.compact,
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: s.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: s.textMuted, height: 1.2),
          ),
        ],
      ),
    );
  }
}
