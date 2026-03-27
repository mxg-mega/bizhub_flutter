import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_icons.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    await _logoController.forward();
    await _textController.forward();

    // Wait a bit before navigating
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      // TODO: Check if user is logged in and onboarding is completed
      // For now, navigate to onboarding
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => Scaffold(
    backgroundColor: AppConfig.primaryColor,
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo Animation
          AnimatedBuilder(
            animation: _logoAnimation,
            builder: (final context, final child) => Transform.scale(
              scale: _logoAnimation.value,
              child: SvgPicture.asset(
                AppIcons.logo,
                width: 120.w,
                height: 120.w,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              // child: Container(
              //   width: 120.w,
              //   height: 120.w,
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(24.r),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black.withOpacity(0.1),
              //         blurRadius: 20,
              //         offset: const Offset(0, 10),
              //       ),
              //     ],
              //   ),
              //   child: Icon(
              //     Icons.business,
              //     size: 60.w,
              //     color: AppConfig.primaryColor,
              //   ),
              // ),
            ),
          ),

          SizedBox(height: 40.h),

          // App Name Animation
          AnimatedBuilder(
            animation: _textAnimation,
            builder: (final context, final child) => Opacity(
              opacity: _textAnimation.value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - _textAnimation.value)),
                child: Text(
                  AppConfig.appName,
                  style: GoogleFonts.inter(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 8.h),

          // App Description Animation
          AnimatedBuilder(
            animation: _textAnimation,
            builder: (final context, final child) => Opacity(
              opacity: _textAnimation.value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - _textAnimation.value)),
                child: Text(
                  AppConfig.appDescription,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          SizedBox(height: 60.h),

          // Loading Indicator
          AnimatedBuilder(
            animation: _textAnimation,
            builder: (final context, final child) => Opacity(
              opacity: _textAnimation.value,
              child: SizedBox(
                width: 40.w,
                height: 40.w,
                child: CircularProgressIndicator(
                  strokeWidth: 3.w,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
