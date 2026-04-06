import 'dart:math';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'register_screen.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  EventFlow Landing Screen
//  Theme: Luxury white-dominant · Black boundaries · Glowing white light
// ═══════════════════════════════════════════════════════════════════════════

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowCtrl;
  late AnimationController _heroCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _shimCtrl;

  late Animation<double> _badgeFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _subSlide;
  late Animation<double> _subFade;
  late Animation<double> _ctaFade;
  late Animation<double> _cardFade;

  final ScrollController _scrollCtrl = ScrollController();
  double _scroll = 0;
  final List<bool> _faqOpen = List.filled(5, false);

  // ─── Palette ──────────────────────────────────────────────────────────────
  static const Color _white     = Color(0xFFFFFFFF);
  static const Color _offWhite  = Color(0xFFF7F6F4);
  static const Color _smoke     = Color(0xFFEDECE9);
  static const Color _mist      = Color(0xFFD5D3CE);
  static const Color _stone     = Color(0xFF9B9891);
  static const Color _charcoal  = Color(0xFF3A3835);
  static const Color _nearBlack = Color(0xFF151412);
  static const Color _ink       = Color(0xFF0A0908);

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);

    _orbCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 14))
      ..repeat();

    _shimCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();

    _heroCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));

    _badgeFade = CurvedAnimation(parent: _heroCtrl,
        curve: const Interval(0.00, 0.35, curve: Curves.easeOut));

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroCtrl,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOut)));
    _titleFade = CurvedAnimation(parent: _heroCtrl,
        curve: const Interval(0.15, 0.55, curve: Curves.easeOut));

    _subSlide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroCtrl,
        curve: const Interval(0.35, 0.70, curve: Curves.easeOut)));
    _subFade = CurvedAnimation(parent: _heroCtrl,
        curve: const Interval(0.35, 0.70, curve: Curves.easeOut));

    _ctaFade = CurvedAnimation(parent: _heroCtrl,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOut));
    _cardFade = CurvedAnimation(parent: _heroCtrl,
        curve: const Interval(0.70, 1.00, curve: Curves.easeOut));

    _heroCtrl.forward();

    _scrollCtrl.addListener(() {
      setState(() => _scroll = _scrollCtrl.offset);
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _heroCtrl.dispose();
    _orbCtrl.dispose();
    _shimCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _white,
      body: Stack(
        children: [
          _buildAmbientLayer(),
          SafeArea(
            child: CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildHero()),
                SliverToBoxAdapter(child: _buildStatsBar()),
                SliverToBoxAdapter(child: _buildFeaturesSection()),
                SliverToBoxAdapter(child: _buildHowItWorksSection()),
                SliverToBoxAdapter(child: _buildWhoWeAreSection()),
                SliverToBoxAdapter(child: _buildPricingSection()),
                SliverToBoxAdapter(child: _buildTestimonialsSection()),
                SliverToBoxAdapter(child: _buildFaqSection()),
                SliverToBoxAdapter(child: _buildCtaBanner()),
                SliverToBoxAdapter(child: _buildFooter()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Ambient glow ──────────────────────────────────────────────────────────
  Widget _buildAmbientLayer() {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowCtrl, _orbCtrl]),
      builder: (_, __) => CustomPaint(
        painter: _AmbientPainter(
            glow: _glowCtrl.value, orb: _orbCtrl.value, scroll: _scroll),
        child: const SizedBox.expand(),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
   Widget _buildHeader() {
     final scrolled = _scroll > 30;
     return AnimatedContainer(
       duration: const Duration(milliseconds: 300),
       decoration: BoxDecoration(
         color: scrolled ? _white.withOpacity(0.94) : Colors.transparent,
         border: scrolled
             ? const Border(bottom: BorderSide(color: Color(0xFFE8E6E0), width: 0.8))
             : null,
     ),
       child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
         child: Row(children: [
          _LogoMark(glowCtrl: _glowCtrl),
          const Spacer(),

           /// ✅ LOGIN (FIXED)
          GestureDetector(
            onTap: _showRolePickerLogin,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               child: Text('Log in',
                  style: TextStyle(
                       color: _stone,
                       fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
           ),

          const SizedBox(width: 8),

           /// ✅ REGISTER (FIXED)
          _BlackPillButton(
            label: 'Get started',
            onTap: _showRolePickerRegister,
           ),
        ]),
      ),
     );
   }
  void _showRolePickerRegister() {
    _showRolePicker((role) {
      Navigator.push(
        context,
        _fadeRoute(RegisterScreen(role: role)),
      );
    });
  }
  void _showRolePickerLogin() {
    _showRolePicker((role) {
      Navigator.push(
        context,
        _fadeRoute(LoginScreen(role: role)),
      );
    });
  }
  void _showRolePicker(Function(UserRole) onSelected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Continue as",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              _roleTile("Attendee", UserRole.attendee, onSelected),
              _roleTile("Organizer", UserRole.organizer, onSelected),
              _roleTile("Venue Owner", UserRole.staff, onSelected),
              _roleTile("Admin", UserRole.superAdmin, onSelected),
            ],
          ),
        );
      },
    );
  }
  Widget _roleTile(String title, UserRole role, Function(UserRole) onSelected) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.pop(context);
        onSelected(role);
      },
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 0),
      child: Column(children: [
        FadeTransition(
          opacity: _badgeFade,
          child: _StatusBadge(glowCtrl: _glowCtrl),
        ),
        const SizedBox(height: 36),
        SlideTransition(
          position: _titleSlide,
          child: FadeTransition(
            opacity: _titleFade,
            child: AnimatedBuilder(
              animation: _shimCtrl,
              builder: (_, __) => _GlowHeadline(shimT: _shimCtrl.value),
            ),
          ),
        ),
        const SizedBox(height: 22),
        SlideTransition(
          position: _subSlide,
          child: FadeTransition(
            opacity: _subFade,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Plan, manage, and deliver world-class events at any scale —\n'
                    'with tools that feel as premium as your experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: _stone, fontSize: 16, height: 1.70, letterSpacing: 0.1),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        FadeTransition(
          opacity: _ctaFade,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _BlackPillButton(
              label: 'Start for free',
              large: true,
              onTap: () => Navigator.push(context,
                  _fadeRoute(const RegisterScreen(role: UserRole.attendee))),
            ),
            const SizedBox(width: 14),
            _GhostPillButton(label: '▶  Watch demo', onTap: () {}),
          ]),
        ),
        const SizedBox(height: 60),
        FadeTransition(
          opacity: _cardFade,
          child: AnimatedBuilder(
            animation: _orbCtrl,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, sin(_orbCtrl.value * 2 * pi) * 7),
              child: _HeroDashboardCard(glowCtrl: _glowCtrl),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Stats bar ─────────────────────────────────────────────────────────────
  Widget _buildStatsBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: _nearBlack,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            _StatCell(value: '50k+', label: 'Events hosted'),
            _StatDivider(),
            _StatCell(value: '2M+', label: 'Attendees'),
            _StatDivider(),
            _StatCell(value: '180+', label: 'Countries'),
            _StatDivider(),
            _StatCell(value: '99.9%', label: 'Uptime'),
          ],
        ),
      ),
    );
  }

  // ── Features ──────────────────────────────────────────────────────────────
  Widget _buildFeaturesSection() {
    final features = [
      _FData(Icons.event_available_rounded, 'Event Management',
          'Create, schedule and manage events with drag-and-drop tools. Supports recurring, multi-day, and hybrid formats.',
          ['Scheduling', 'Templates', 'Recurring']),
      _FData(Icons.group_rounded, 'Multi-Role System',
          'Granular permissions for admins, organizers, speakers, sponsors and attendees — all in one place.',
          ['RBAC', 'Permissions', 'Teams']),
      _FData(Icons.bar_chart_rounded, 'Real-time Analytics',
          'Track registrations, check-ins, engagement and revenue with live dashboards and exportable reports.',
          ['Dashboards', 'Reports', 'Export']),
      _FData(Icons.qr_code_scanner_rounded, 'Smart Check-in',
          'QR and NFC-powered check-in handling thousands per minute — even fully offline.',
          ['QR Code', 'NFC', 'Offline']),
      _FData(Icons.palette_outlined, 'Custom Branding',
          'White-label every touchpoint — pages, badges, emails and apps — with your brand identity.',
          ['White-label', 'Themes', 'Domain']),
      _FData(Icons.extension_rounded, '300+ Integrations',
          'One-click connections to Salesforce, HubSpot, Stripe, Zoom, Slack and hundreds more.',
          ['Salesforce', 'Stripe', 'Zapier']),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Features'),
          const SizedBox(height: 14),
          const Text('Everything your\nevent deserves.',
              style: TextStyle(
                color: _nearBlack,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1.10,
                letterSpacing: -1.5,
              )),
          const SizedBox(height: 40),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _FeatureCard(data: f),
          )),
        ],
      ),
    );
  }

  // ── How it works ──────────────────────────────────────────────────────────
  Widget _buildHowItWorksSection() {
    const steps = [
      ('01', 'Create your event',
          'Guided builder sets date, format and capacity in under two minutes.'),
      ('02', 'Invite & manage',
          'Send branded invites, manage registrations and assign team roles effortlessly.'),
      ('03', 'Go live',
          'Seamless check-in, session management and real-time engagement on event day.'),
      ('04', 'Analyze & grow',
          'Deep post-event analytics to make the next experience even better.'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'How it works'),
          const SizedBox(height: 14),
          const Text('Live in four\nsteps.',
              style: TextStyle(
                color: _nearBlack,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1.10,
                letterSpacing: -1.5,
              )),
          const SizedBox(height: 36),
          ...steps.asMap().entries.map((e) => _StepRow(
            number: e.value.$1,
            title: e.value.$2,
            desc: e.value.$3,
            isLast: e.key == steps.length - 1,
          )),
        ],
      ),
    );
  }

  // ── Who we are ────────────────────────────────────────────────────────────
  Widget _buildWhoWeAreSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Who we are'),
          const SizedBox(height: 14),
          const Text('Built by event people,\nfor event people.',
              style: TextStyle(
                color: _nearBlack,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1.10,
                letterSpacing: -1.5,
              )),
          const SizedBox(height: 22),
          const Text(
            'EventFlow was born at a 3,000-person conference where the check-in app crashed, '
                'the ticketing platform charged 18%, and analytics lived in six different spreadsheets.\n\n'
                'We are engineers, event producers, and product designers who have run events on six '
                'continents. We built the platform we always wished existed — fast, fair-priced, and a genuine joy to use.',
            style: TextStyle(color: _stone, fontSize: 14, height: 1.80),
          ),
          const SizedBox(height: 36),
          const _TeamCard(
            initials: 'UA',
            name: 'Ummara Amin',
            role: 'CEO & Co-founder',
            bio: 'Seasoned event strategist with 10+ years producing large-scale conferences across South Asia and the Middle East.',
          ),
          const SizedBox(height: 12),
          const _TeamCard(
            initials: 'HA',
            name: 'Hafsa Ayesha',
            role: 'CTO & Co-founder',
            bio: 'Full-stack engineer and systems architect. Previously built real-time ticketing infrastructure for 500k+ concurrent users.',
          ),
          const SizedBox(height: 12),
          const _TeamCard(
            initials: 'AF',
            name: 'Amna Farooq',
            role: 'Head of Product',
            bio: 'Product designer turned builder. Obsessed with attendee-first experiences and interfaces that simply work.',
          ),
        ],
      ),
    );
  }

  // ── Events Showcase ───────────────────────────────────────────────────────
  Widget _buildPricingSection() {
    final events = [
      _EventData(
        tag: 'Tech',
        title: 'DevSummit Islamabad 2026',
        date: 'Mar 14 · Islamabad, PK',
        attendees: '1,200',
        status: 'Live',
        statusLive: true,
      ),
      _EventData(
        tag: 'Design',
        title: 'UX Unplugged — Spring Edition',
        date: 'Apr 2 · Lahore, PK',
        attendees: '340',
        status: 'Upcoming',
        statusLive: false,
      ),
      _EventData(
        tag: 'Business',
        title: 'Startup Pitch Night',
        date: 'Apr 18 · Karachi, PK',
        attendees: '580',
        status: 'Upcoming',
        statusLive: false,
      ),
      _EventData(
        tag: 'Education',
        title: 'EduTech Forum 2026',
        date: 'May 6 · Online',
        attendees: '4,800',
        status: 'Upcoming',
        statusLive: false,
      ),
      _EventData(
        tag: 'Community',
        title: 'WomenInTech Conference',
        date: 'May 22 · Rawalpindi, PK',
        attendees: '900',
        status: 'Open',
        statusLive: false,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Live on EventFlow'),
          const SizedBox(height: 14),
          const Text('Events happening\nright now.',
              style: TextStyle(
                color: _nearBlack,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1.10,
                letterSpacing: -1.5,
              )),
          const SizedBox(height: 8),
          const Text(
            'A glimpse of what\'s running on EventFlow today.',
            style: TextStyle(color: _stone, fontSize: 14),
          ),
          const SizedBox(height: 32),
          ...events.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _EventCard(data: e),
          )),
        ],
      ),
    );
  }

  // ── Testimonials ──────────────────────────────────────────────────────────
  Widget _buildTestimonialsSection() {
    const reviews = [
      ('Sarah K.', 'Head of Events · TechCorp',
          'We moved 12 annual conferences to EventFlow in a weekend. The check-in system alone saved three hours per event.'),
      ('James T.', 'Founder · MeetupLondon',
          'The analytics are on another level. I finally understand which sessions drive re-registration.'),
      ('Amara N.', 'Community Lead · DevCircle',
          'Custom branding used to cost us \$10k a year. On Pro it\'s just included. Mind-blowing value.'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Testimonials'),
          const SizedBox(height: 14),
          const Text('Loved by thousands\nof event teams.',
              style: TextStyle(
                color: _nearBlack,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1.10,
                letterSpacing: -1.5,
              )),
          const SizedBox(height: 32),
          ...reviews.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TestimonialCard(
                name: r.$1, title: r.$2, quote: r.$3),
          )),
        ],
      ),
    );
  }

  // ── FAQ ───────────────────────────────────────────────────────────────────
  Widget _buildFaqSection() {
    const faqs = [
      ('What is EventFlow?',
          'EventFlow is an all-in-one event management platform for planning, running, and analyzing in-person, virtual, and hybrid events of any size.'),
      ('Is there a free plan?',
          'Yes — our Starter plan is completely free for events up to 100 attendees. No credit card required.'),
      ('Do you charge per-ticket fees?',
          'Never on paid plans. Starter has a small 2% processing fee; Pro and Enterprise have zero platform fees.'),
      ('Can I white-label the platform?',
          'Pro includes custom colors and domain. Enterprise includes a fully white-labeled mobile app under your brand.'),
      ('How does offline check-in work?',
          'The app caches all attendee data locally. Scans happen instantly offline and sync the moment you reconnect.'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'FAQ'),
          const SizedBox(height: 14),
          const Text('Questions,\nanswered.',
              style: TextStyle(
                color: _nearBlack,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1.10,
                letterSpacing: -1.5,
              )),
          const SizedBox(height: 32),
          ...faqs.asMap().entries.map((e) => _FaqTile(
            q: e.value.$1,
            a: e.value.$2,
            open: _faqOpen[e.key],
            onToggle: () =>
                setState(() => _faqOpen[e.key] = !_faqOpen[e.key]),
          )),
        ],
      ),
    );
  }

  // ── CTA Banner ────────────────────────────────────────────────────────────
  Widget _buildCtaBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
      child: AnimatedBuilder(
        animation: _glowCtrl,
        builder: (_, __) => Container(
          padding: const EdgeInsets.fromLTRB(30, 44, 30, 44),
          decoration: BoxDecoration(
            color: _nearBlack,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25 + _glowCtrl.value * 0.08),
                blurRadius: 60,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.03 + _glowCtrl.value * 0.04),
                blurRadius: 1,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(children: [
            // Glow orb dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white
                        .withOpacity(0.5 + _glowCtrl.value * 0.4),
                    blurRadius: 12 + _glowCtrl.value * 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Ready to run your\nbest event yet?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1.15,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Join 50,000+ event professionals worldwide.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.40), fontSize: 14),
            ),
            const SizedBox(height: 32),
            _WhitePillButton(
              label: 'Start for free — no card needed',
              onTap: () => Navigator.push(context,
                  _fadeRoute(const RegisterScreen(role: UserRole.attendee))),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
      child: Column(children: [
        Container(height: 0.6, color: _smoke),
        const SizedBox(height: 36),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _LogoMark(glowCtrl: _glowCtrl),
                const SizedBox(height: 10),
                const Text('Run events beautifully.',
                    style: TextStyle(color: _stone, fontSize: 12)),
                const SizedBox(height: 8),
                const Text('© 2026 EventFlow Inc.',
                    style: TextStyle(color: _mist, fontSize: 11)),
              ]),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: _FooterCol(heading: 'Product',
                  links: ['Features', 'Pricing', 'Changelog', 'Integrations']),
            ),
            const Expanded(
              child: _FooterCol(heading: 'Company',
                  links: ['About', 'Blog', 'Careers', 'Contact']),
            ),
          ],
        ),
      ]),
    );
  }

  // ─── util ─────────────────────────────────────────────────────────────────
  Route _fadeRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a, __, child) =>
        FadeTransition(opacity: a, child: child),
    transitionDuration: const Duration(milliseconds: 380),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  AMBIENT PAINTER
// ═══════════════════════════════════════════════════════════════════════════
class _AmbientPainter extends CustomPainter {
  final double glow, orb, scroll;
  _AmbientPainter({required this.glow, required this.orb, required this.scroll});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFFFFFF));

    _blob(canvas,
        cx: size.width * 0.12 + sin(orb * 2 * pi) * 22,
        cy: size.height * 0.12 + cos(orb * 2 * pi) * 16 - scroll * 0.25,
        r: 230,
        opacity: 0.03 + glow * 0.02);

    _blob(canvas,
        cx: size.width * 0.88 + cos(orb * 2 * pi * 0.8) * 18,
        cy: size.height * 0.20 + sin(orb * 2 * pi * 0.8) * 28 - scroll * 0.12,
        r: 200,
        opacity: 0.025 + glow * 0.015);

    _blob(canvas,
        cx: size.width * 0.50,
        cy: size.height * 0.55 - scroll * 0.08,
        r: 260,
        opacity: 0.018 + glow * 0.010);
  }

  void _blob(Canvas canvas,
      {required double cx, required double cy, required double r, required double opacity}) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF000000).withOpacity(opacity),
          const Color(0xFF000000).withOpacity(0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, paint);
  }

  @override
  bool shouldRepaint(_AmbientPainter o) =>
      o.glow != glow || o.orb != orb || o.scroll != scroll;
}

// ═══════════════════════════════════════════════════════════════════════════
//  GLOW HEADLINE
// ═══════════════════════════════════════════════════════════════════════════
class _GlowHeadline extends StatelessWidget {
  final double shimT;
  const _GlowHeadline({required this.shimT});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: const [
          Color(0xFF0A0908),
          Color(0xFF666360),
          Color(0xFF0A0908),
          Color(0xFF0A0908),
        ],
        stops: [
          0.0,
          (shimT * 1.4).clamp(0.0, 1.0),
          ((shimT * 1.4) + 0.14).clamp(0.0, 1.0),
          1.0,
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      child: const Text(
        'Run Events\nBeautifully',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 56,
          height: 1.02,
          letterSpacing: -2.8,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  LOGO MARK
// ═══════════════════════════════════════════════════════════════════════════
class _LogoMark extends StatelessWidget {
  final AnimationController glowCtrl;
  const _LogoMark({required this.glowCtrl});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      AnimatedBuilder(
        animation: glowCtrl,
        builder: (_, __) => Container(
          width: 9, height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0A0908),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15 + glowCtrl.value * 0.15),
                blurRadius: 10 + glowCtrl.value * 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 9),
      const Text('EventFlow',
          style: TextStyle(
            color: Color(0xFF0A0908),
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.6,
          )),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STATUS BADGE
// ═══════════════════════════════════════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final AnimationController glowCtrl;
  const _StatusBadge({required this.glowCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowCtrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F3F0),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xFFE0DED8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04 + glowCtrl.value * 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0A0908),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3 + glowCtrl.value * 0.3),
                  blurRadius: 6 + glowCtrl.value * 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Now in public beta · Free to start',
            style: TextStyle(
              color: Color(0xFF3A3835),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  HERO DASHBOARD CARD
// ═══════════════════════════════════════════════════════════════════════════
class _HeroDashboardCard extends StatelessWidget {
  final AnimationController glowCtrl;
  const _HeroDashboardCard({required this.glowCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowCtrl,
      builder: (_, __) => Container(
        height: 230,
        decoration: BoxDecoration(
          color: const Color(0xFF0E0D0C),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF2A2826)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22 + glowCtrl.value * 0.08),
              blurRadius: 50,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.03 + glowCtrl.value * 0.03),
              blurRadius: 1,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const _DashboardContent(),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  static Widget _dot(Color c) => Container(
      width: 9, height: 9,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c));

  static Widget _miniStat(String label, String val, Color valColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(val,
              style: TextStyle(
                  color: valColor, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF5A5856), fontSize: 10, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _dot(const Color(0xFFFF5F57)),
          const SizedBox(width: 5),
          _dot(const Color(0xFFFFBD2E)),
          const SizedBox(width: 5),
          _dot(const Color(0xFF28C840)),
          const SizedBox(width: 14),
          const Text('EventFlow Dashboard',
              style: TextStyle(
                  color: Color(0xFF4A4845), fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          _miniStat('Events Live', '12', Colors.white),
          const SizedBox(width: 10),
          _miniStat('Attendees', '4.2k', const Color(0xFFCCCBCA)),
          const SizedBox(width: 10),
          _miniStat('Revenue', '\$38k', const Color(0xFFAAAAAA)),
        ]),
        const SizedBox(height: 16),
        _BarChart(),
      ]),
    );
  }
}

class _BarChart extends StatelessWidget {
  static const _heights = [0.38, 0.62, 0.48, 0.80, 0.58, 1.0, 0.72];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final isHigh = i == 5;
        return Container(
          width: 24,
          height: 44 * _heights[i],
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: isHigh
                  ? [Colors.white, Colors.white60]
                  : [Colors.white24, Colors.white10],
            ),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  BUTTONS
// ═══════════════════════════════════════════════════════════════════════════
class _BlackPillButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool large;

  const _BlackPillButton(
      {required this.label, required this.onTap, this.large = false});

  @override
  State<_BlackPillButton> createState() => _BlackPillButtonState();
}

class _BlackPillButtonState extends State<_BlackPillButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Transform.scale(
          scale: 1.0 - _c.value * 0.03,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.large ? 28 : 20,
              vertical: widget.large ? 15 : 11,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0908),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20 - _c.value * 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(widget.label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: widget.large ? 15 : 13,
                  letterSpacing: 0.1,
                )),
          ),
        ),
      ),
    );
  }
}

class _GhostPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GhostPillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xFFD5D3CE)),
        ),
        child: const Text('▶  Watch demo',
            style: TextStyle(
              color: Color(0xFF9B9891),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            )),
      ),
    );
  }
}

class _WhitePillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _WhitePillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.15),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Text('Start for free — no card needed',
            style: TextStyle(
              color: Color(0xFF0A0908),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            )),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SECTION LABEL
// ═══════════════════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEEA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0DDD7)),
      ),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF9B9891),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STATS
// ═══════════════════════════════════════════════════════════════════════════
class _StatCell extends StatelessWidget {
  final String value, label;
  const _StatCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          )),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.35),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          )),
    ]);
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 0.5, height: 32, color: Colors.white.withOpacity(0.12));
}

// ═══════════════════════════════════════════════════════════════════════════
//  FEATURE DATA + CARD
// ═══════════════════════════════════════════════════════════════════════════
class _FData {
  final IconData icon;
  final String title, description;
  final List<String> tags;
  const _FData(this.icon, this.title, this.description, this.tags);
}

class _FeatureCard extends StatefulWidget {
  final _FData data;
  const _FeatureCard({required this.data});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hov;

  @override
  void initState() {
    super.initState();
    _hov = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
  }

  @override
  void dispose() {
    _hov.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hov.forward(),
      onTapUp: (_) => _hov.reverse(),
      onTapCancel: () => _hov.reverse(),
      child: AnimatedBuilder(
        animation: _hov,
        builder: (_, __) {
          final t = _hov.value;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color.lerp(
                  const Color(0xFFF9F8F6), const Color(0xFF0A0908), t),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Color.lerp(
                    const Color(0xFFE5E3DD), Colors.transparent, t)!,
              ),
              boxShadow: t > 0.5
                  ? [const BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 40,
                  offset: Offset(0, 12))]
                  : [],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                        const Color(0xFFECEAE4),
                        Colors.white.withOpacity(0.08),
                        t),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.data.icon,
                      color: Color.lerp(
                          const Color(0xFF3A3835), Colors.white, t),
                      size: 18),
                ),
                const Spacer(),
                Icon(Icons.arrow_outward_rounded,
                    color: Color.lerp(
                        const Color(0xFFCECBC4), Colors.white38, t),
                    size: 16),
              ]),
              const SizedBox(height: 16),
              Text(widget.data.title,
                  style: TextStyle(
                    color: Color.lerp(
                        const Color(0xFF151412), Colors.white, t),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  )),
              const SizedBox(height: 8),
              Text(widget.data.description,
                  style: TextStyle(
                    color: Color.lerp(
                        const Color(0xFF9B9891), Colors.white54, t),
                    fontSize: 13,
                    height: 1.65,
                  )),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: widget.data.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color.lerp(
                        const Color(0xFFE8E5DF),
                        Colors.white.withOpacity(0.07),
                        t),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(tag,
                      style: TextStyle(
                        color: Color.lerp(
                            const Color(0xFF6B6965), Colors.white60, t),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      )),
                )).toList(),
              ),
            ]),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  STEP ROW
// ═══════════════════════════════════════════════════════════════════════════
class _StepRow extends StatelessWidget {
  final String number, title, desc;
  final bool isLast;
  const _StepRow(
      {required this.number,
        required this.title,
        required this.desc,
        required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0908),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  )),
            ),
          ),
          if (!isLast)
            Expanded(
              child: Container(
                width: 0.8,
                color: const Color(0xFFE0DDD7),
                margin: const EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          if (isLast) const SizedBox(height: 32),
        ]),
        const SizedBox(width: 18),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                    color: Color(0xFF151412),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 5),
              Text(desc,
                  style: const TextStyle(
                    color: Color(0xFF9B9891),
                    fontSize: 13,
                    height: 1.60,
                  )),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  TEAM CARD  – 3 members with black glowing avatar
// ═══════════════════════════════════════════════════════════════════════════
class _TeamCard extends StatelessWidget {
  final String initials, name, role, bio;
  const _TeamCard({
    required this.initials,
    required this.name,
    required this.role,
    required this.bio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E3DD)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Glowing black avatar
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0A0908),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.5,
                )),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: const TextStyle(
                  color: Color(0xFF151412),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                )),
            const SizedBox(height: 3),
            Text(role,
                style: const TextStyle(
                  color: Color(0xFF9B9891),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                )),
            const SizedBox(height: 10),
            Text(bio,
                style: const TextStyle(
                  color: Color(0xFF6B6965),
                  fontSize: 13,
                  height: 1.60,
                )),
          ]),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  EVENT DATA + CARD
// ═══════════════════════════════════════════════════════════════════════════
class _EventData {
  final String tag, title, date, attendees, status;
  final bool statusLive;
  const _EventData({
    required this.tag,
    required this.title,
    required this.date,
    required this.attendees,
    required this.status,
    required this.statusLive,
  });
}

class _EventCard extends StatefulWidget {
  final _EventData data;
  const _EventCard({required this.data});

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hov;

  @override
  void initState() {
    super.initState();
    _hov = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _hov.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hov.forward(),
      onTapUp: (_) => _hov.reverse(),
      onTapCancel: () => _hov.reverse(),
      child: AnimatedBuilder(
        animation: _hov,
        builder: (_, __) {
          final t = _hov.value;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color.lerp(
                  const Color(0xFFF9F8F6), const Color(0xFF0A0908), t),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Color.lerp(
                    const Color(0xFFE5E3DD), Colors.transparent, t)!,
              ),
              boxShadow: t > 0.4
                  ? [
                const BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 30,
                    offset: Offset(0, 8))
              ]
                  : [],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: Color.lerp(
                              const Color(0xFFECEAE4),
                              Colors.white.withOpacity(0.10),
                              t),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          widget.data.tag.toUpperCase(),
                          style: TextStyle(
                            color: Color.lerp(
                                const Color(0xFF6B6965), Colors.white60, t),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.data.title,
                        style: TextStyle(
                          color: Color.lerp(
                              const Color(0xFF151412), Colors.white, t),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 11,
                            color: Color.lerp(
                                const Color(0xFF9B9891), Colors.white38, t)),
                        const SizedBox(width: 5),
                        Text(
                          widget.data.date,
                          style: TextStyle(
                            color: Color.lerp(
                                const Color(0xFF9B9891), Colors.white38, t),
                            fontSize: 12,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.people_rounded,
                            size: 11,
                            color: Color.lerp(
                                const Color(0xFF9B9891), Colors.white38, t)),
                        const SizedBox(width: 5),
                        Text(
                          '${widget.data.attendees} registered',
                          style: TextStyle(
                            color: Color.lerp(
                                const Color(0xFF9B9891), Colors.white38, t),
                            fontSize: 12,
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: widget.data.statusLive
                            ? Color.lerp(const Color(0xFF0A0908),
                            Colors.white.withOpacity(0.12), t)
                            : Color.lerp(const Color(0xFFECEAE4),
                            Colors.white.withOpacity(0.08), t),
                        borderRadius: BorderRadius.circular(100),
                        border: widget.data.statusLive
                            ? Border.all(
                            color: Color.lerp(
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.2),
                                t)!)
                            : null,
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (widget.data.statusLive)
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                              Color.lerp(Colors.white, Colors.white70, t),
                            ),
                          ),
                        Text(
                          widget.data.status,
                          style: TextStyle(
                            color: widget.data.statusLive
                                ? Color.lerp(Colors.white, Colors.white70, t)
                                : Color.lerp(const Color(0xFF6B6965),
                                Colors.white54, t),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),
                    Icon(Icons.arrow_outward_rounded,
                        size: 16,
                        color: Color.lerp(
                            const Color(0xFFCECBC4), Colors.white38, t)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════
//  TESTIMONIAL CARD
// ═══════════════════════════════════════════════════════════════════════════
class _TestimonialCard extends StatelessWidget {
  final String name, title, quote;
  const _TestimonialCard(
      {required this.name, required this.title, required this.quote});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F8F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E3DD)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: List.generate(5, (_) => const Padding(
            padding: EdgeInsets.only(right: 2),
            child: Icon(Icons.star_rounded,
                color: Color(0xFF0A0908), size: 13),
          )),
        ),
        const SizedBox(height: 14),
        Text('"$quote"',
            style: const TextStyle(
              color: Color(0xFF3A3835),
              fontSize: 14,
              height: 1.72,
              fontStyle: FontStyle.italic,
            )),
        const SizedBox(height: 18),
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0A0908),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Center(
              child: Text(name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  )),
            ),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: const TextStyle(
                  color: Color(0xFF151412),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                )),
            Text(title,
                style: const TextStyle(
                    color: Color(0xFF9B9891), fontSize: 11)),
          ]),
        ]),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  FAQ TILE
// ═══════════════════════════════════════════════════════════════════════════
class _FaqTile extends StatelessWidget {
  final String q, a;
  final bool open;
  final VoidCallback onToggle;
  const _FaqTile(
      {required this.q, required this.a, required this.open, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: open ? const Color(0xFF0A0908) : const Color(0xFFF9F8F6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: open ? Colors.transparent : const Color(0xFFE5E3DD),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(q,
                    style: TextStyle(
                      color: open ? Colors.white : const Color(0xFF151412),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    )),
              ),
              AnimatedRotation(
                turns: open ? 0.125 : 0,
                duration: const Duration(milliseconds: 260),
                child: Icon(Icons.add_rounded,
                    color: open
                        ? Colors.white38
                        : const Color(0xFF9B9891),
                    size: 20),
              ),
            ]),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(a,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.48),
                      fontSize: 13,
                      height: 1.70,
                    )),
              ),
              crossFadeState: open
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 260),
            ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  FOOTER COLUMN
// ═══════════════════════════════════════════════════════════════════════════
class _FooterCol extends StatelessWidget {
  final String heading;
  final List<String> links;
  const _FooterCol({required this.heading, required this.links});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(heading,
          style: const TextStyle(
            color: Color(0xFF3A3835),
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 0.3,
          )),
      const SizedBox(height: 12),
      ...links.map((l) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Text(l,
            style: const TextStyle(
                color: Color(0xFF9B9891), fontSize: 13)),
      )),
    ]);
  }
}