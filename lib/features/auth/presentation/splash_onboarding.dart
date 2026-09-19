import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/services/auth_session.dart';

const Color darkBlue = Color(0xFF0B1C6D);
const Color lightBlue = Color(0xFF1BB1E7);
const Color leafGreen = Color(0xFF6BCF9C);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> fillAnim;
  late final Animation<double> splitAnim;
  late final Animation<double> leafAnim;
  late final Animation<double> uiFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    fillAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeInOut),
    );

    splitAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.65, curve: Curves.easeInOutCubic),
    );

    leafAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 0.9, curve: Curves.easeOutBack),
    );

    uiFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  void _goToOnboarding() {
    Navigator.pushReplacementNamed(
      context,
      AuthSession.isLoggedIn ? '/home' : '/onboarding',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 160,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(160, 60),
                        painter: PillPainter(
                          fill: fillAnim.value,
                          split: splitAnim.value,
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, -28 * leafAnim.value),
                        child: Transform.scale(
                          scale: leafAnim.value.clamp(0.0, 1.0),
                          child: Opacity(
                            opacity: leafAnim.value.clamp(0.0, 1.0),
                            child: const Leaf(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Opacity(
                  opacity: uiFade.value,
                  child: const Text(
                    'DAWAYA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Opacity(
                  opacity: uiFade.value,
                  child: SizedBox(
                    width: 120,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _goToOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Start',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PillPainter extends CustomPainter {
  final double fill;
  final double split;

  PillPainter({required this.fill, required this.split});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const double pillWidth = 120;
    const double pillHeight = 32;

    if (split < 0.05) {
      final filledWidth = pillWidth * fill;
      final clipRect = Rect.fromCenter(
        center: center,
        width: filledWidth,
        height: pillHeight,
      );

      canvas.save();
      canvas.clipRect(clipRect);
      _drawWholePill(canvas, center, pillWidth, pillHeight);
      canvas.restore();
      return;
    }

    final separation = split * 32;
    final angle = split * pi / 10;

    _drawHalf(
      canvas,
      center.translate(-separation, -separation * 0),
      pillWidth,
      pillHeight,
      darkBlue,
      left: true,
      rotation: -angle,
    );

    _drawHalf(
      canvas,
      center.translate(separation, separation * 0),
      pillWidth,
      pillHeight,
      lightBlue,
      left: false,
      rotation: angle,
    );
  }

  void _drawWholePill(
    Canvas canvas,
    Offset center,
    double width,
    double height,
  ) {
    _drawHalf(canvas, center, width, height, darkBlue, left: true);
    _drawHalf(canvas, center, width, height, lightBlue, left: false);
  }

  void _drawHalf(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    Color color, {
    required bool left,
    double rotation = 0,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final path = Path();
    final r = height / 2;

    if (left) {
      path.moveTo(-width / 2, -r);
      path.lineTo(0, -r);
      path.lineTo(0, r);
      path.lineTo(-width / 2, r);
      path.arcToPoint(
        Offset(-width / 2, -r),
        radius: Radius.circular(r),
      );
    } else {
      path.moveTo(0, -r);
      path.lineTo(width / 2, -r);
      path.arcToPoint(
        Offset(width / 2, r),
        radius: Radius.circular(r),
      );
      path.lineTo(0, r);
      path.close();
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Leaf extends StatelessWidget {
  const Leaf({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -pi / 6,
      child: Container(
        width: 26,
        height: 18,
        decoration: const BoxDecoration(
          color: leafGreen,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(4),
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> pages = [
    _OnboardingData(
      image: 'lib/assets/image4.png',
      title: 'Search any medicine instantly',
      description:
          'It’s not available, we suggest an alternative medicine with safe ingredients.',
    ),
    _OnboardingData(
      image: 'lib/assets/image6.png',
      title: 'Scan prescriptions',
      description:
          'Take a photo of your prescription and let the app detect medicines accurately.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (_, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          page.image,
                          height: 260,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 260,
                              width: 260,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color.from(
                                  alpha: 1,
                                  red: 0.933,
                                  green: 0.933,
                                  blue: 0.933,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 80,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFF0B1C6D)
                        : const Color.from(
                            alpha: 1,
                            red: 0.878,
                            green: 0.878,
                            blue: 0.878,
                          ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B1C6D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      _currentPage == pages.length - 1 ? 'Start' : 'Next',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String image;
  final String title;
  final String description;

  _OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}
