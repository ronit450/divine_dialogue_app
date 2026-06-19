import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

const _kDevs = [
  _Dev(
    id: 'ronit',
    name: 'Ronit Kumar',
    role: 'Founder',
    monogram: 'RK',
    tint: AppColors.hinduOrange,
    short: 'Building dialogue with the divine.',
    long: 'The mind behind Divine Chat. Ronit built this app out of a '
        'deep curiosity about how technology can bring people closer to their '
        'spiritual roots — without diluting the tradition. He reads everything '
        'users send and cares deeply about getting the answers right.',
    email: 'ronit@divine-dialogue.app',
    linkedin: 'linkedin.com/in/ronitkumar',
    github: 'github.com/ronit450',
    website: 'ronitkumar.dev',
  ),
  _Dev(
    id: 'faraz',
    name: 'Faraz Ali',
    role: 'Founder',
    monogram: 'FA',
    tint: AppColors.islamGreen,
    short: 'Co-building this with care.',
    long: 'Faraz co-founded Divine Chat with a focus on making the '
        'Islamic tradition feel alive and accessible through honest, '
        'well-sourced answers. He brings both engineering discipline and a '
        'genuine reverence for the texts to everything he works on.',
    email: 'faraz@divine-dialogue.app',
    linkedin: 'linkedin.com/in/farazali',
    github: 'github.com/farazali',
    website: 'farazali.dev',
  ),
];

class _Dev {
  const _Dev({
    required this.id,
    required this.name,
    required this.role,
    required this.monogram,
    required this.tint,
    required this.short,
    required this.long,
    required this.email,
    required this.linkedin,
    required this.github,
    required this.website,
  });
  final String id, name, role, monogram, short, long;
  final String email, linkedin, github, website;
  final Color tint;
}

class DevelopersScreen extends StatefulWidget {
  const DevelopersScreen({super.key});

  @override
  State<DevelopersScreen> createState() => _DevelopersScreenState();
}

class _DevelopersScreenState extends State<DevelopersScreen> {
  String? _openDevId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.nightBg : AppColors.boneBg;
    final fg = isDark ? AppColors.nightFg : AppColors.boneFg;
    final muted = isDark ? AppColors.nightMuted : AppColors.boneMuted;
    final line = isDark ? AppColors.nightLine : AppColors.boneLine;
    final surface = isDark ? AppColors.nightSurface : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: line),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded, size: 14, color: fg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Developers',
                        style: GoogleFonts.cormorantGaramond(
                          color: fg, fontSize: 28, fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 18),
                      child: Text(
                        'Divine Chat is built by two people. Tap a card to '
                        'learn more or reach out — we read everything.',
                        style: GoogleFonts.inter(
                          color: muted, fontSize: 13, height: 1.55,
                        ),
                      ),
                    ),
                    Text(
                      'THE TEAM',
                      style: GoogleFonts.jetBrainsMono(
                        color: muted, fontSize: 10, letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._kDevs.map((dev) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DevCard(
                        dev: dev,
                        fg: fg, muted: muted, line: line, surface: surface,
                        onTap: () => setState(() => _openDevId = dev.id),
                      ),
                    )),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: line),
                      ),
                      child: Text.rich(
                        TextSpan(
                          style: GoogleFonts.inter(
                            color: muted, fontSize: 12, height: 1.5,
                          ),
                          children: [
                            const TextSpan(text: 'Want to say something? Use '),
                            TextSpan(
                              text: 'Report an issue',
                              style: GoogleFonts.inter(
                                color: fg, fontWeight: FontWeight.w500,
                              ),
                            ),
                            const TextSpan(text: ' or email us directly.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_openDevId != null)
            _DevPopup(
              dev: _kDevs.firstWhere((d) => d.id == _openDevId),
              isDark: isDark,
              bg: bg, fg: fg, muted: muted, line: line, surface: surface,
              onClose: () => setState(() => _openDevId = null),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Developer card (list item)
// ──────────────────────────────────────────

class _DevCard extends StatelessWidget {
  const _DevCard({
    required this.dev,
    required this.fg,
    required this.muted,
    required this.line,
    required this.surface,
    required this.onTap,
  });
  final _Dev dev;
  final Color fg, muted, line, surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            _Monogram(dev: dev, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dev.name,
                    style: GoogleFonts.inter(
                      color: fg, fontSize: 15.5, fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dev.role.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      color: dev.tint, fontSize: 9.5, letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dev.short,
                    style: GoogleFonts.inter(
                      color: muted, fontSize: 13, height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: muted, size: 18),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// Monogram avatar
// ──────────────────────────────────────────

class _Monogram extends StatelessWidget {
  const _Monogram({required this.dev, required this.size});
  final _Dev dev;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dev.tint,
        boxShadow: [
          BoxShadow(
            color: dev.tint.withValues(alpha: 0.25),
            blurRadius: size * 0.4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          dev.monogram,
          style: GoogleFonts.cormorantGaramond(
            color: Colors.white,
            fontSize: size * 0.32,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
// Contact row inside popup
// ──────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
    required this.fg,
    required this.muted,
    required this.line,
    required this.bg,
    this.divider = true,
  });
  final IconData icon;
  final String label, value;
  final Color tint, fg, muted, line, bg;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (divider) Divider(height: 1, color: line),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8), color: bg,
                ),
                child: Icon(icon, color: tint, size: 14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: GoogleFonts.jetBrainsMono(
                        color: muted, fontSize: 9, letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: GoogleFonts.inter(color: fg, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: muted, size: 14),
            ],
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────
// Developer popup modal
// ──────────────────────────────────────────

class _DevPopup extends StatelessWidget {
  const _DevPopup({
    required this.dev,
    required this.isDark,
    required this.bg,
    required this.fg,
    required this.muted,
    required this.line,
    required this.surface,
    required this.onClose,
  });
  final _Dev dev;
  final bool isDark;
  final Color bg, fg, muted, line, surface;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: line),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tinted header band
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [
                          dev.tint.withValues(alpha: 0.13),
                          dev.tint.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Monogram(dev: dev, size: 64),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                dev.name,
                                style: GoogleFonts.cormorantGaramond(
                                  color: fg, fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic, height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dev.role.toUpperCase(),
                                style: GoogleFonts.jetBrainsMono(
                                  color: dev.tint, fontSize: 10, letterSpacing: 1.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: onClose,
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: surface,
                              border: Border.all(color: line),
                            ),
                            child: Icon(Icons.close_rounded, color: fg, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bio + contacts (scrollable)
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ABOUT',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: muted, fontSize: 9, letterSpacing: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  dev.long,
                                  style: GoogleFonts.inter(
                                    color: fg, fontSize: 14, height: 1.55,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: line),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: Column(
                                children: [
                                  _ContactRow(
                                    icon: Icons.mail_outline_rounded,
                                    label: 'Email', value: dev.email,
                                    tint: dev.tint, fg: fg, muted: muted,
                                    line: line, bg: bg, divider: false,
                                  ),
                                  _ContactRow(
                                    icon: Icons.work_outline_rounded,
                                    label: 'LinkedIn', value: dev.linkedin,
                                    tint: dev.tint, fg: fg, muted: muted,
                                    line: line, bg: bg,
                                  ),
                                  _ContactRow(
                                    icon: Icons.code_rounded,
                                    label: 'GitHub', value: dev.github,
                                    tint: dev.tint, fg: fg, muted: muted,
                                    line: line, bg: bg,
                                  ),
                                  _ContactRow(
                                    icon: Icons.language_rounded,
                                    label: 'Website', value: dev.website,
                                    tint: dev.tint, fg: fg, muted: muted,
                                    line: line, bg: bg,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: line)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.favorite_rounded, color: dev.tint, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Made with care',
                              style: GoogleFonts.inter(color: muted, fontSize: 12),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: onClose,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: fg,
                            ),
                            child: Text(
                              'Close',
                              style: GoogleFonts.inter(
                                color: bg, fontSize: 12, fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
