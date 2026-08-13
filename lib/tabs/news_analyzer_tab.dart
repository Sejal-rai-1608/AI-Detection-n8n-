import 'package:flutter/material.dart';
import 'package:n8ntrial/models/models.dart';
import 'package:n8ntrial/models/app_state.dart';
import 'package:n8ntrial/tabs/backtrack_tab.dart';
import 'package:n8ntrial/services/api_service.dart';
import 'dart:convert';

class NewsAnalyzerTab extends StatefulWidget {
  const NewsAnalyzerTab({super.key});

  @override
  State<NewsAnalyzerTab> createState() => _NewsAnalyzerTabState();
}

class _NewsAnalyzerTabState extends State<NewsAnalyzerTab> with SingleTickerProviderStateMixin {
  final TextEditingController _newsTextController = TextEditingController();
  final ApiService _apiService = ApiService();
  
  NewsPreset? _activeAnalysis;
  bool _isAnalyzing = false;
  String? _errorMessage;
  late TabController _resultTabController;

  @override
  void initState() {
    super.initState();
    _resultTabController = TabController(length: 2, vsync: this);
    appState.onTriggerNewsAnalysis = _triggerAnalysis;
  }

  @override
  void dispose() {
    if (appState.onTriggerNewsAnalysis == _triggerAnalysis) {
      appState.onTriggerNewsAnalysis = null;
    }
    _resultTabController.dispose();
    _newsTextController.dispose();
    super.dispose();
  }

  NewsPreset _parseN8nResponse(String originalText, Map<String, dynamic> rawResult) {
    if (rawResult.containsKey("textResponse")) {
      final textResp = rawResult["textResponse"] as String;
      return NewsPreset(
        title: "Plain Text Analysis",
        content: originalText,
        source: "n8n Webhook Response",
        score: 50.0,
        category: "Unverified",
        flaggedPhrases: const [],
        metrics: const {
          "AI Confidence": 0.5,
          "Sensationalism Index": 0.5,
          "Fact-Check Match": 0.5,
        },
        rawResponse: textResp,
        backtrackReport: const BacktrackReport(
          originalSource: "Plain Text Output",
          originalLogo: "PT",
          firstPublishedDate: "Recent Scans",
          websiteHistory: "No JSON payload returned. Response displayed as raw text.",
          reverseImageSources: [],
          factCheckArticles: [],
          timelineOfReposts: [],
        ),
      );
    }

    Map<String, dynamic> result = rawResult;
    if (rawResult.containsKey("output")) {
      final outputVal = rawResult["output"];
      if (outputVal is Map<String, dynamic>) {
        result = outputVal;
      } else if (outputVal is String) {
        try {
          final decoded = jsonDecode(outputVal);
          if (decoded is Map<String, dynamic>) {
            result = decoded;
          }
        } catch (_) {
          result = {
            "verdict": "Suspicious",
            "confidence": 70.0,
            "explanation": outputVal,
          };
        }
      }
    }

    final String verdict = (result["verdict"] ?? result["status"] ?? "Fake").toString();
    final lowerVerdict = verdict.toLowerCase();
    bool isFake = true;
    if (lowerVerdict.contains("true") ||
        lowerVerdict.contains("safe") ||
        lowerVerdict.contains("factual") ||
        lowerVerdict.contains("real") ||
        lowerVerdict.contains("credible")) {
      isFake = false;
    }

    double confidence = 75.0;
    final rawConfidence = result["confidence"];
    if (rawConfidence != null) {
      if (rawConfidence is num) {
        confidence = rawConfidence.toDouble();
      } else {
        final confStr = rawConfidence.toString().replaceAll('%', '').trim();
        confidence = double.tryParse(confStr) ?? 75.0;
      }
    }

    final score = isFake ? (100.0 - confidence).clamp(0.0, 49.0) : confidence.clamp(50.0, 100.0);

    final explanation = (result["explanation"] ?? result["reason"] ?? "").toString();

    List<String> sources = [];
    if (result["supportingSources"] is List) {
      sources = List<String>.from((result["supportingSources"] as List).map((e) => e.toString()));
    } else if (result["sources"] is List) {
      sources = List<String>.from((result["sources"] as List).map((e) => e.toString()));
    }

    List<String> flags = [];
    if (result["redFlags"] is List) {
      flags = List<String>.from((result["redFlags"] as List).map((e) => e.toString()));
    } else if (result["reason"] != null) {
      flags = [result["reason"].toString()];
    }

    final List<Map<String, String>> timelineList = [];
    if (result["timeline"] != null && result["timeline"] is List) {
      for (var t in (result["timeline"] as List)) {
        timelineList.add({
          "time": "Propagation Node",
          "account": t.toString(),
          "post": "Misinformation spread log tracked.",
        });
      }
    } else {
      timelineList.addAll([
        {"time": "10 mins ago", "account": "Social Media Node", "post": "Flagged viral forward."},
        {"time": "Original", "account": "Anonymous server node", "post": "Source reference point."},
      ]);
    }

    final backtrack = BacktrackReport(
      originalSource: sources.isNotEmpty ? sources.first : "Primary Registry Node",
      originalLogo: sources.isNotEmpty ? (sources.first.length >= 2 ? sources.first.substring(0, 2).toUpperCase() : "SR") : "PR",
      firstPublishedDate: "Recent Scans",
      websiteHistory: explanation.isNotEmpty ? explanation : "First logged reference",
      reverseImageSources: const [],
      factCheckArticles: sources,
      timelineOfReposts: timelineList,
    );

    return NewsPreset(
      title: "n8n Verification Report",
      content: originalText,
      source: sources.isNotEmpty ? sources.first : "n8n Webhook Response",
      score: score,
      category: verdict,
      flaggedPhrases: flags,
      explanation: explanation,
      redFlags: flags,
      supportingSources: sources,
      metrics: {
        "AI Confidence": confidence / 100,
        "Sensationalism Index": isFake ? 0.8 : 0.2,
        "Fact-Check Match": isFake ? 0.3 : 0.9,
      },
      backtrackReport: backtrack,
    );
  }

  void _triggerAnalysis(NewsPreset preset) async {
    if (!mounted) return;
    setState(() {
      _isAnalyzing = true;
      _activeAnalysis = null;
      _errorMessage = null;
      _newsTextController.text = preset.content;
    });

    try {
      final response = await _apiService.verifyNews(preset.content);
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _activeAnalysis = _parseN8nResponse(preset.content, response);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _activeAnalysis = preset; // Fallback to preset offline data
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("n8n Webhook connection offline. Switched to mock preset data."),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _runCustomAnalysis() async {
    final rawText = _newsTextController.text.trim();
    if (rawText.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _activeAnalysis = null;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.verifyNews(rawText);
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _activeAnalysis = _parseN8nResponse(rawText, response);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    }
  }

  void _runOfflineSimulation() {
    final rawText = _newsTextController.text.trim();
    if (rawText.isEmpty) return;

    setState(() {
      _isAnalyzing = false;
      _errorMessage = null;
      
      String text = rawText.toLowerCase();
      double score = 92.0; 
      List<String> flagged = [];
      double sensationalism = 0.1;
      double bias = 0.1;

      if (text.contains("secret") || text.contains("leak") || text.contains("anonymous")) {
        score -= 30;
        flagged.add("secret");
        sensationalism += 0.4;
      }
      if (text.contains("control") || text.contains("conspiracy") || text.contains("proven")) {
        score -= 25;
        flagged.add("control");
        bias += 0.3;
      }

      final isFake = score < 50;

      _activeAnalysis = NewsPreset(
        title: "Offline Simulation Report",
        content: rawText,
        source: "User Verified Text",
        score: score.clamp(5.0, 99.0),
        category: isFake ? "Fake" : "Real",
        flaggedPhrases: flagged,
        metrics: {
          "AI Confidence": isFake ? 0.85 : 0.95,
          "Linguistic Bias Index": bias.clamp(0.0, 1.0),
          "Sensationalism Index": sensationalism.clamp(0.0, 1.0),
          "Fact-Check Match": (score / 100).clamp(0.0, 1.0),
        },
        backtrackReport: newsDatabase[0].backtrackReport,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        final presetsWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "CHOOSE SUSPECT PRESETS:",
              style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF4361EE), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: newsDatabase.length,
                itemBuilder: (context, index) {
                  final preset = newsDatabase[index];
                  return GestureDetector(
                    onTap: () => _triggerAnalysis(preset),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF101726),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1B233D)),
                      ),
                      child: Text(
                        preset.title.length > 25 ? "${preset.title.substring(0, 25)}..." : preset.title,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );

        final inputCard = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF101726),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _newsTextController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Enter suspect news text or article URL...",
                  hintStyle: TextStyle(color: Colors.white30, fontSize: 13),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const Divider(color: Color(0xFF1E293B)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "ENGINE STATUS: SECURE",
                    style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.grey[500]),
                  ),
                  ElevatedButton(
                    onPressed: _isAnalyzing ? null : _runCustomAnalysis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4361EE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("VERIFY FACTS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                ],
              )
            ],
          ),
        );

        final loadingWidget = _isAnalyzing
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFF4361EE)),
                      SizedBox(height: 12),
                      Text("RUNNING AI INTEGRITY VERIFICATION...", style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey)),
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
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "WEBHOOK TIMEOUT / CONNECTION OFFLINE",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Error description: $_errorMessage\n\nNote: Verify n8n webhook URL status and CORS origins configurations. You can run offline simulator for testing.",
                      style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _runOfflineSimulation,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF4361EE)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text(
                              "RUN OFFLINE SIMULATION",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: Color(0xFF4361EE),
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
                        presetsWidget,
                        const SizedBox(height: 16),
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
                    child: _activeAnalysis != null
                        ? _buildResultCard(_activeAnalysis!)
                        : Container(
                            height: 250,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFF101726),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF1E293B)),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.analytics_outlined, size: 40, color: Colors.grey),
                                SizedBox(height: 12),
                                Text(
                                  "Select a preset or input text to run verification facts dashboard.",
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
              presetsWidget,
              const SizedBox(height: 16),
              inputCard,
              loadingWidget,
              errorWidget,
              if (_activeAnalysis != null) ...[
                const SizedBox(height: 20),
                _buildResultCard(_activeAnalysis!),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultCard(NewsPreset report) {
    final bool isFake = report.score < 50;
    final Color accentColor = isFake ? const Color(0xFFFF2A54) : const Color(0xFF2EC4B6);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101726),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _resultTabController,
            indicatorColor: const Color(0xFF4361EE),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            tabs: const [
              Tab(text: "Result"),
              Tab(text: "Analysis"),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accentColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "VERDICT: ${report.category.toUpperCase()}",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentColor, fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Source: ${report.source}",
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accentColor.withOpacity(0.2)),
                        ),
                        child: Text(
                          "${report.score.round()}% TRUST",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: accentColor, fontFamily: 'monospace'),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 230,
                  child: TabBarView(
                    controller: _resultTabController,
                    children: [
                      // TAB 1: RESULT BODY
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "EVALUATION SUMMARY",
                              style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              report.content,
                              style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                            ),
                            if (report.explanation != null && report.explanation!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                "EXPLANATION",
                                style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                report.explanation!,
                                style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                              ),
                            ],
                            if (report.rawResponse != null && report.rawResponse!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                "VERIFICATION RESPONSE",
                                style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                report.rawResponse!,
                                style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                              ),
                            ],
                            if (report.flaggedPhrases.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                "FLAGGED KEY PHRASES",
                                style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: report.flaggedPhrases.map((phrase) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF2A54).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFFF2A54).withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      phrase,
                                      style: const TextStyle(fontSize: 10, color: Color(0xFFFF2A54), fontFamily: 'monospace'),
                                    ),
                                  );
                                }).toList(),
                              )
                            ]
                          ],
                        ),
                      ),

                      // TAB 2: ANALYSIS CHARTS & METRICS
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "AI PROFILES & CREDIBILITY",
                              style: TextStyle(fontFamily: 'monospace', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            ...report.metrics.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(entry.key, style: const TextStyle(fontSize: 11, color: Colors.white70)),
                                        Text(
                                          "${(entry.value * 100).round()}%",
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4361EE), fontFamily: 'monospace'),
                                        )
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: entry.value,
                                        minHeight: 6,
                                        backgroundColor: const Color(0xFF1E293B),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          entry.key.contains("Sensationalism") || entry.key.contains("Bias")
                                              ? const Color(0xFFFF2A54)
                                              : const Color(0xFF2EC4B6),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (isFake && report.backtrackReport != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      appState.requestBacktrack(report.title, report.backtrackReport!);
                      _showBacktrackBottomSheet(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFFFF2A54),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFFFF2A54), width: 1.5),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.radar, size: 16),
                    label: const Text("Source Backtracking", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    if (report.supportingSources != null && report.supportingSources!.isNotEmpty) {
                      _showSourcesBottomSheet(context, report.supportingSources!);
                    } else if (report.backtrackReport != null && report.backtrackReport!.factCheckArticles.isNotEmpty) {
                      _showSourcesBottomSheet(context, report.backtrackReport!.factCheckArticles);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No supporting sources found for this report.")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.article_outlined, size: 16),
                  label: const Text("Fact Check Articles", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text("Share Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showBacktrackBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              const Expanded(
                child: BacktrackTab(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSourcesBottomSheet(BuildContext context, List<String> sources) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "SUPPORTING SOURCES",
                style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sources.length,
                  itemBuilder: (context, index) {
                    final source = sources[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101726),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              source,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                            ),
                          ),
                          const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}
