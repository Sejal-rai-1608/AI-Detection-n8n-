import 'package:flutter/material.dart';
import 'package:n8ntrial/models/models.dart';
import 'package:n8ntrial/services/api_service.dart';
import 'dart:convert';

class UrlAnalyzerTab extends StatefulWidget {
  const UrlAnalyzerTab({super.key});

  @override
  State<UrlAnalyzerTab> createState() => _UrlAnalyzerTabState();
}

class _UrlAnalyzerTabState extends State<UrlAnalyzerTab> {
  final TextEditingController _urlController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isAnalyzing = false;
  String _currentStep = "";
  String? _errorMessage;
  Map<String, dynamic>? _analysisResult;

  final List<String> _scanSteps = [
    "🌐 Fetching webpage...",
    "📄 Extracting article...",
    "🤖 AI analyzing claims...",
    "🔍 Cross-checking trusted sources...",
    "📊 Preparing fact-check report..."
  ];

  bool _validateUrl(String url) {
    if (url.isEmpty) {
      setState(() {
        _errorMessage = "URL cannot be empty. Please enter a URL to scan.";
      });
      return false;
    }
    final uri = Uri.tryParse(url);
    final isValid = uri != null && 
                    (uri.scheme == 'http' || uri.scheme == 'https') && 
                    uri.hasAuthority;
    if (!isValid) {
      setState(() {
        _errorMessage = "Invalid URL format. Please enter a valid link starting with http:// or https://";
      });
      return false;
    }
    return true;
  }

  void _runUrlAnalysis() async {
    final rawUrl = _urlController.text.trim();
    if (!_validateUrl(rawUrl)) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
      _errorMessage = null;
      _currentStep = _scanSteps[0];
    });

    // Step animations
    for (int i = 0; i < _scanSteps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        _currentStep = _scanSteps[i];
      });
    }

    try {
      final rawResponse = await _apiService.verifyUrl(rawUrl);
      if (!mounted) return;

      Map<String, dynamic> response = rawResponse;
      if (rawResponse.containsKey("output")) {
        final outputVal = rawResponse["output"];
        if (outputVal is Map<String, dynamic>) {
          response = outputVal;
        } else if (outputVal is String) {
          try {
            final decoded = jsonDecode(outputVal);
            if (decoded is Map<String, dynamic>) {
              response = decoded;
            } else {
              response = {
                "textResponse": outputVal,
              };
            }
          } catch (e) {
            response = {
              "textResponse": outputVal,
            };
          }
        }
      }

      setState(() {
        _isAnalyzing = false;
        _analysisResult = response;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    }
  }

  void _runOfflineSimulation() async {
    final rawUrl = _urlController.text.trim();
    if (!_validateUrl(rawUrl)) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
      _errorMessage = null;
      _currentStep = _scanSteps[0];
    });

    for (int i = 0; i < _scanSteps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _currentStep = _scanSteps[i];
      });
    }

    final isSuspicious = rawUrl.contains("free") || rawUrl.contains("gift") || rawUrl.contains("giveaway") || rawUrl.contains("win");

    setState(() {
      _isAnalyzing = false;
      _analysisResult = isSuspicious
          ? {
              "articleTitle": "Exclusive IPL Ticket Giveaway: Register Now to Claim Free VIP Passes",
              "mainClaim": "Users can claim free VIP IPL tickets and an iPhone 15 by registering on this promotional domain.",
              "verdict": "Fake",
              "confidence": 98,
              "explanation": "This webpage hosts a classic phishing scam. The claim of a free giveaway is entirely fabricated to steal user credentials. Official IPL and Apple authorities have confirmed no such promotions exist.",
              "sources": [
                "BCCI Official Website",
                "Apple Support Alert Database",
                "Cyber Security India Advisory"
              ],
              "category": "Phishing & Scams",
              "recommendation": "Do not enter any personal credentials, mobile numbers, or OTPs. Exit the webpage immediately."
            }
          : {
              "articleTitle": "Scientists Discover New Species of Deep-Sea Coral in Marianas",
              "mainClaim": "Marine biologists have discovered a previously unknown species of deep-sea coral at 4,000 meters depth in the Mariana Trench.",
              "verdict": "Real",
              "confidence": 95,
              "explanation": "The article is fully accurate and aligns with the peer-reviewed research published in the Journal of Marine Science. The discovery was verified by NOAA research vessels and international oceanographic teams.",
              "sources": [
                "NOAA Ocean Exploration",
                "Journal of Marine Biology",
                "Nature Science News"
              ],
              "category": "Science & Environment",
              "recommendation": "This is a verified and highly credible scientific report. Safe to reference and share."
            };
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        final inputCard = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "PASTE ARTICLE URL FOR FACT-CHECK",
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4338CA),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                maxLines: 1,
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: "https://example.com/article-to-verify",
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.link, size: 18),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _runUrlAnalysis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.fact_check, size: 16),
                label: const Text(
                  "VERIFY ARTICLE CONTENT",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        );

        final loadingWidget = _isAnalyzing
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(strokeWidth: 3),
                      const SizedBox(height: 16),
                      Text(
                        _currentStep,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink();

        final errorWidget = _errorMessage != null
            ? Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.error.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "WEBHOOK TIMEOUT / CONNECTION OFFLINE",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Error description: $_errorMessage\n\nNote: Placeholders aren't connected yet. You can launch offline simulation for demo purposes.",
                      style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _runOfflineSimulation,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.colorScheme.secondary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              "RUN OFFLINE SIMULATION",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink();

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        inputCard,
                        const SizedBox(height: 16),
                        loadingWidget,
                        errorWidget,
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: _analysisResult != null
                      ? _buildAnalysisReport(theme, isDark, _analysisResult!)
                      : Container(
                          height: 250,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.fact_check_outlined, size: 40, color: Colors.grey),
                              SizedBox(height: 12),
                              Text(
                                "Enter article URL to verify the factual accuracy of its content.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              inputCard,
              if (_isAnalyzing) loadingWidget,
              if (_errorMessage != null) errorWidget,
              if (_analysisResult != null) ...[
                const SizedBox(height: 20),
                _buildAnalysisReport(theme, isDark, _analysisResult!),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalysisReport(ThemeData theme, bool isDark, Map<String, dynamic> result) {
    if (result.containsKey("textResponse")) {
      final textResp = result["textResponse"] as String;
      final accentColor = theme.colorScheme.primary;
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ARTICLE ANALYSIS",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accentColor, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Fact Check Result // Plain Text",
                        style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  Icon(Icons.article_outlined, color: accentColor, size: 24),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    textResp,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, height: 1.5),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    }

    final analysisResult = UrlAnalysisResult.fromJson(result);
    final articleTitle = analysisResult.articleTitle.isNotEmpty ? analysisResult.articleTitle : "Untitled Article";
    final mainClaim = analysisResult.mainClaim.isNotEmpty ? analysisResult.mainClaim : "No claim specified.";
    final verdict = analysisResult.verdict.isNotEmpty ? analysisResult.verdict : "Unknown";
    final rawConfidence = analysisResult.confidence;
    final explanation = analysisResult.explanation.isNotEmpty ? analysisResult.explanation : "No explanation available.";
    final category = analysisResult.category.isNotEmpty ? analysisResult.category : "General";
    final recommendation = analysisResult.recommendation.isNotEmpty ? analysisResult.recommendation : "No recommendation available.";
    final List<String> sources = analysisResult.sources;

    final verdictLower = verdict.toString().toLowerCase();
    Color verdictColor;
    IconData verdictIcon;
    if (verdictLower == 'real' || verdictLower == 'true' || verdictLower == 'verified') {
      verdictColor = const Color(0xFF10B981); // Green
      verdictIcon = Icons.check_circle_outline;
    } else if (verdictLower == 'fake' || verdictLower == 'false' || verdictLower == 'misleading' || verdictLower == 'phishing') {
      verdictColor = const Color(0xFFEF4444); // Red
      verdictIcon = Icons.cancel_outlined;
    } else {
      verdictColor = const Color(0xFFF59E0B); // Amber
      verdictIcon = Icons.help_outline_outlined;
    }

    final confidencePercent = rawConfidence.toDouble().clamp(0.0, 100.0);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Card: Verdict Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: verdictColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ARTICLE VERIFICATION REPORT",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: verdictColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(verdictIcon, color: verdictColor, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            "Verdict: $verdict",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Confidence",
                      style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: verdictColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${confidencePercent.round()}%",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: verdictColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Article Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("📰", style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Article Title",
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            articleTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // 2. Main Claim
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("📌", style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Main Claim",
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              mainClaim,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white70 : Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Verdict (Explicit)
                Row(
                  children: [
                    const Text("✅", style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    const Text(
                      "Verdict: ",
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      verdict,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: verdictColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4. Confidence (Explicit with Progress Bar)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("🎯", style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        const Text(
                          "Confidence: ",
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${confidencePercent.round()}%",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: verdictColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: confidencePercent / 100.0,
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        color: verdictColor,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. Category
                Row(
                  children: [
                    const Text("📂", style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    const Text(
                      "Category: ",
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // 6. Explanation
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("📝", style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Explanation",
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            explanation,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // 7. Recommendation
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("💡", style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Recommendation",
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              recommendation,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black87,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // 8. Supporting Sources
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("🔗", style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Supporting Sources",
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (sources.isEmpty)
                            const Text(
                              "No verified sources listed.",
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: sources.map((src) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: theme.dividerColor),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.public, size: 12, color: theme.colorScheme.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        src,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
