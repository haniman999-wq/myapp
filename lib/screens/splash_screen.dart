import 'dart:async';

import 'package:flutter/material.dart';

import 'main_screen.dart';

const Color _kPrimaryGreen = Color(0xFF38C77F);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _gatherScale;
  late final Animation<double> _flashScale;
  late final Animation<double> _flashOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _gatherScale = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeInBack),
      ),
    );
    _flashScale = Tween<double>(begin: 0.0, end: 60.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 1.0, curve: Curves.easeIn),
      ),
    );
    _flashOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.75, curve: Curves.easeIn),
      ),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    await _controller.forward();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, animation, _) => const MainScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPrimaryGreen,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: ClipOval(
                  child: Transform.scale(
                    scale: _gatherScale.value,
                    child: Container(
                      width: 320,
                      height: 320,
                      color: _kPrimaryGreen,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      child: const Text(
                        '씽크 뱅크\n베리나이스',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: Center(
                  child: Opacity(
                    opacity: _flashOpacity.value,
                    child: Transform.scale(
                      scale: _flashScale.value,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
