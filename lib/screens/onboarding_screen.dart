import 'package:flutter/material.dart';
import 'package:n8ntrial/models/app_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      title: "AI Fact Scanning",
      subtitle: "Paste text or articles to instantly verify credibility using global fact-check integrations coordinated via n8n automation pipelines.",
      icon: Icons.fact_check_outlined,
      gradient: [Color(0xFF4338CA), Color(0xFF6366F1)],
    ),
    OnboardingSlideData(
      title: "Image Forensics",
      subtitle: "Detect manipulation, inspect EXIF sensor metadata, run reverse image matches, and identify StyleGAN/Deepfake artificial generations.",
      icon: Icons.image_search_outlined,
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
    ),
    OnboardingSlideData(
      title: "Source Backtracking",
      subtitle: "Trace misinformation back to its origin across social portals with interactive propagation timelines and site trust index reports.",
      icon: Icons.radar_outlined,
      gradient: [Color(0xFFEF4444), Color(0xFFDC2626)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete onboarding in state
      appState.completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextButton(
                  onPressed: () => appState.completeOnboarding(),
                  child: Text(
                    "SKIP",
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildSlide(_slides[index], theme, isDark);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => _buildPageIndicator(index),
                    ),
                  ),

                  // Floating Navigation Button
                  FloatingActionButton(
                    onPressed: _onNextPage,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _currentPage == _slides.length - 1
                          ? Icons.done
                          : Icons.arrow_forward,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(OnboardingSlideData data, ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Graphic container matching Perplexity/Apple premium styling
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: data.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: data.gradient[0].withOpacity(0.3),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              data.icon,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),

          // Glassmorphic Card containing text
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingSlideData {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;

  const OnboardingSlideData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });
}
