import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../app_router.dart';
import '../ussd_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _decideNavigation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Animations ────────────────────────────────────────────────────────────

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  // ── Navigation logic ──────────────────────────────────────────────────────

  Future<void> _decideNavigation() async {
    // Wait for animation to complete
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final isOnboarded = prefs.getBool('is_onboarded') ?? false;

    if (!mounted) return;

    if (!isOnboarded) {
      // First time — go to onboarding
      Navigator.of(context).pushReplacementNamed(AppRouter.onboarding);
      return;
    }

    // Returning user — check app PIN
    final appPinEnabled = prefs.getBool('app_pin_enabled') ?? false;
    final appPin = prefs.getString('app_pin') ?? '';

    if (appPinEnabled && appPin.isNotEmpty) {
      // Show app PIN screen
      Navigator.of(context).pushReplacementNamed(AppRouter.appPin);
      return;
    }

    // No PIN — go straight to home
    // Load cached SIM preference
    final savedSubId = prefs.getInt('preferred_sub_id');
    if (savedSubId != null) {
      try {
        final slots = await UssdService.getSimSlots();
        AppState.preferredSim = slots.firstWhere(
          (s) => s.subscriptionId == savedSubId,
          orElse: () => slots.first,
        );
      } catch (_) {}
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRouter.home);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // ── Logo + App name ─────────────────────────────────────────
              AnimatedBuilder(
                animation: _controller,
                builder: (_, child) => FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: child,
                  ),
                ),
                child: Column(
                  children: [
                    // Logo circle
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '₹',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // App name
                    const Text(
                      'OfflinePay',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Tagline
                    Text(
                      'Payments without internet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // ── Bottom — powered by *99# ────────────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: Column(
                    children: [
                      Text(
                        'Powered by',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '*99# USSD Banking',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
