import 'package:flutter/material.dart';
import 'package:n8ntrial/models/app_state.dart';
import 'package:n8ntrial/models/models.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userName = appState.currentUser?['name'] ?? "Agent";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Greeting & Profile Header Block
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello, $userName 👋",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Launch AI investigation pipeline",
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              // Dynamic profile indicator
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    userName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Smart Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.15 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Input news text or paste URL link...",
                      hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38, fontSize: 13),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87, fontFamily: 'monospace'),
                    onSubmitted: (val) {
                      if (val.trim().startsWith("http")) {
                        appState.startVerifyUrl(val.trim());
                      } else {
                        appState.startVerifyNews(NewsPreset(
                          title: "Manual Scan Request",
                          content: val.trim(),
                          source: "User Clipboard Input",
                          score: 50.0,
                          category: "Custom",
                          flaggedPhrases: const [],
                          metrics: const {},
                        ));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.search, color: theme.colorScheme.primary, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Three Premium Cards with visual gradient backgrounds
          const Text(
            "CORE INVESTIGATION DECKS",
            style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWideLayout = constraints.maxWidth >= 700;
              final newsCard = _buildPremiumDeckCard(
                title: "Verify News Integrity",
                description: "Analyze articles for clickbait headers, bias indexes, and fact-checking validations.",
                icon: Icons.article_outlined,
                gradient: const [Color(0xFF4338CA), Color(0xFF6366F1)], // Indigo Gradient
                onTap: () => appState.startVerifyNews(newsDatabase[0]),
              );
              final imageCard = _buildPremiumDeckCard(
                title: "Image & Deepfake Forensics",
                description: "Scan files for ELA pixel edits, metadata tags, and StyleGAN computer generations.",
                icon: Icons.image_search_outlined,
                gradient: const [Color(0xFF10B981), Color(0xFF059669)], // Emerald Gradient
                onTap: () => appState.startVerifyImage(imageDatabase[0]),
              );
              final urlCard = _buildPremiumDeckCard(
                title: "Verify URL Article Content",
                description: "Verify the factual accuracy of the article content located at a URL link.",
                icon: Icons.link_outlined,
                gradient: const [Color(0xFFEF4444), Color(0xFFF59E0B)], // Red/Amber warning Gradient
                onTap: () => appState.startVerifyUrl(""),
              );
              final videoCard = _buildPremiumDeckCard(
                title: "Video Deepfake Forensics",
                description: "Scan video clips for vocal splicing, lip-sync cloning, and face morphing deepfakes.",
                icon: Icons.video_camera_back_outlined,
                gradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)], // Violet/purple Gradient
                onTap: () => appState.startVerifyVideo(),
              );

              if (isWideLayout) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: newsCard),
                    const SizedBox(width: 14),
                    Expanded(child: imageCard),
                    const SizedBox(width: 14),
                    Expanded(child: urlCard),
                    const SizedBox(width: 14),
                    Expanded(child: videoCard),
                  ],
                );
              } else {
                return Column(
                  children: [
                    newsCard,
                    const SizedBox(height: 14),
                    imageCard,
                    const SizedBox(height: 14),
                    urlCard,
                    const SizedBox(height: 14),
                    videoCard,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 28),

          // Quick Actions Grid
          const Text(
            "QUICK UTILITIES",
            style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWideLayout = constraints.maxWidth >= 700;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWideLayout ? 5 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isWideLayout ? 1.8 : 2.2,
                children: [
                  _buildQuickActionTile(
                    "File Forensic",
                    Icons.folder_open_outlined,
                    const Color(0xFF6366F1),
                    () => appState.startVerifyImage(imageDatabase[0]),
                  ),
                  _buildQuickActionTile(
                    "Audio Scan",
                    Icons.settings_voice_outlined,
                    const Color(0xFF10B981),
                    () => appState.startVerifyNews(newsDatabase[0]),
                  ),
                  _buildQuickActionTile(
                    "URL Verify",
                    Icons.link_outlined,
                    const Color(0xFFF59E0B),
                    () => appState.startVerifyUrl(""),
                  ),
                  _buildQuickActionTile(
                    "Video Scan",
                    Icons.video_library_outlined,
                    const Color(0xFF8B5CF6),
                    () => appState.startVerifyVideo(),
                  ),
                  _buildQuickActionTile(
                    "API Status",
                    Icons.api_outlined,
                    const Color(0xFFEF4444),
                    () {
                      appState.setDashboardIndex(5);
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // AI Tips section (Notion style)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: Color(0xFFF59E0B), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI TIP OF THE DAY",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Always review domain structures carefully. Phishing links often substitute letter glyphs (e.g. 'arnazon.com' instead of 'amazon.com') to bypass security filters.",
                        style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPremiumDeckCard({
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.16),
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
