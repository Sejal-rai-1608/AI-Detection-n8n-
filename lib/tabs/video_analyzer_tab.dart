import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:n8ntrial/models/video_analysis_model.dart';
import 'package:n8ntrial/services/api_service.dart';
import 'dart:io' show File;
import 'dart:async';

class VideoAnalyzerTab extends StatefulWidget {
  const VideoAnalyzerTab({super.key});

  @override
  State<VideoAnalyzerTab> createState() => _VideoAnalyzerTabState();
}

class _VideoAnalyzerTabState extends State<VideoAnalyzerTab> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedVideo;
  VideoPlayerController? _videoController;

  bool _isAnalyzing = false;
  String _currentStep = "";
  String? _errorMessage;
  VideoAnalysisResult? _analysisResult;
  String? _textResponse; // For plain text fallbacks

  final List<String> _scanSteps = [
    "🎥 Uploading video...",
    "🖼 Extracting key frames...",
    "🎤 Generating transcript...",
    "🤖 AI analyzing...",
    "🔍 Verifying facts...",
    "📊 Preparing report...",
  ];

  Future<void> _pickVideo(ImageSource source) async {
    try {
      setState(() {
        _errorMessage = null;
      });
      
      final XFile? video = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );

      if (video == null) return;

      // Dispose existing controller if any
      if (_videoController != null) {
        await _videoController!.dispose();
      }

      VideoPlayerController controller;
      if (kIsWeb) {
        controller = VideoPlayerController.networkUrl(Uri.parse(video.path));
      } else {
        controller = VideoPlayerController.file(File(video.path));
      }

      await controller.initialize();
      
      setState(() {
        _selectedVideo = video;
        _videoController = controller;
        _analysisResult = null;
        _textResponse = null;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load video: ${e.toString().replaceAll("Exception: ", "")}";
      });
    }
  }

  void _runVideoAnalysis() async {
    if (_selectedVideo == null) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
      _textResponse = null;
      _errorMessage = null;
      _currentStep = "📡 Transmitting video payload to n8n workflow...";
    });

    // We cycle through the steps dynamically while the API is executing
    Timer? messageTimer;
    int tickCount = 0;
    final loadingMessages = [
      "📡 Transmitting video payload to n8n webhook...",
      "🎥 Uploading video assets to TwelveLabs...",
      "🖼 Indexing video frames and visual structures...",
      "🎤 Transcribing audio stream and dialogue...",
      "🤖 AI Agent generating summary & analysis...",
      "🔍 Formulating truth verdict and gathering sources...",
      "📊 Compiling forensic report details...",
      "⏳ Finalizing response, please hold on..."
    ];

    messageTimer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (!mounted || !_isAnalyzing) {
        t.cancel();
        return;
      }
      setState(() {
        _currentStep = loadingMessages[tickCount % loadingMessages.length];
        tickCount++;
      });
    });

    try {
      // Read bytes from video file
      final bytes = await _selectedVideo!.readAsBytes();
      final filename = _selectedVideo!.name;

      // Check for large file warning in UI
      if (bytes.length > 50 * 1024 * 1024) {
        throw Exception("File size exceeds 50MB. Please select a shorter or lower resolution video.");
      }

      final rawResponse = await _apiService.verifyVideo(bytes, filename);
      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
      });
      messageTimer.cancel();

      if (rawResponse.containsKey("textResponse")) {
        setState(() {
          _textResponse = rawResponse["textResponse"];
        });
      } else {
        setState(() {
          _analysisResult = VideoAnalysisResult.fromJson(rawResponse);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
      messageTimer.cancel();
    }
  }

  void _runOfflineSimulation() async {
    if (_selectedVideo == null) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
      _textResponse = null;
      _errorMessage = null;
      _currentStep = _scanSteps[0];
    });

    for (int i = 0; i < _scanSteps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        _currentStep = _scanSteps[i];
      });
    }

    final isManipulated = _selectedVideo!.name.toLowerCase().contains("fake") || 
                          _selectedVideo!.name.toLowerCase().contains("deepfake") || 
                          _selectedVideo!.name.toLowerCase().contains("edit") ||
                          _selectedVideo!.name.toLowerCase().contains("leak");

    setState(() {
      _isAnalyzing = false;
      if (isManipulated) {
        _analysisResult = const VideoAnalysisResult(
          videoTitle: "Viral Cabinet Meeting Leak - AI Voice Over Dub",
          summary: "A viral video purporting to show a cabinet minister discussing illegal trade agreements is analyzed for manipulation.",
          mainClaim: "Cabinet Minister admitted to accepting foreign payoffs during private assembly.",
          verdict: "Fake / Manipulated",
          confidence: 94,
          explanation: "AI audio diagnostics detected speech synthesis markers at 15 seconds. The vocal timbre matches public AI voice templates. Deepfake probability is extremely high.",
          manipulationDetected: true,
          deepfakeProbability: 95,
          misleadingSegments: [
            MisleadingSegment(timestamp: "00:00:12", reason: "Audio track spliced with voice clone"),
            MisleadingSegment(timestamp: "00:00:15", reason: "Lip-sync morphing mismatch (Deepfake)"),
            MisleadingSegment(timestamp: "00:00:32", reason: "Cut transition overlayed with fake audio"),
          ],
          sources: [
            "Reuters Fact Check",
            "Ministry of Information Press Release",
            "Deepfake Forensics Laboratory"
          ],
        );
      } else {
        _analysisResult = const VideoAnalysisResult(
          videoTitle: "Official NASA Moon Mission Launch Briefing",
          summary: "NASA administrators detail the trajectory and astronaut payload scheduling for Artemis III mission launch.",
          mainClaim: "Artemis III remains scheduled for orbital deployment within current fiscal calendar.",
          verdict: "True / Verified",
          confidence: 98,
          explanation: "The broadcast matches live streams from NASA Press Room. Cryptographic signatures are intact, and voice biometrics show absolute synchronization with target profiles.",
          manipulationDetected: false,
          deepfakeProbability: 2,
          misleadingSegments: [],
          sources: [
            "NASA TV Live Broadcast Archive",
            "ESA Artemis Cooperation Agreement Catalog",
            "AP News Science Registry"
          ],
        );
      }
    });
  }

  void _clearSelectedVideo() async {
    if (_videoController != null) {
      await _videoController!.dispose();
    }
    setState(() {
      _selectedVideo = null;
      _videoController = null;
      _analysisResult = null;
      _textResponse = null;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        final pickerCard = Container(
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
                "VERIFY VIDEO FORENSICS",
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4338CA),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedVideo == null) ...[
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickVideo(ImageSource.gallery),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.video_library, size: 32, color: theme.colorScheme.primary),
                              const SizedBox(height: 8),
                              const Text(
                                "Gallery Upload",
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickVideo(ImageSource.camera),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.videocam, size: 32, color: theme.colorScheme.primary),
                              const SizedBox(height: 8),
                              const Text(
                                "Record Video",
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Video Preview Panel
                if (_videoController != null && _videoController!.value.isInitialized) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: Colors.black,
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            VideoPlayer(_videoController!),
                            // Controls overlay
                            _ControlsOverlay(controller: _videoController!),
                            VideoProgressIndicator(
                              _videoController!,
                              allowScrubbing: true,
                              colors: VideoProgressColors(
                                playedColor: theme.colorScheme.primary,
                                bufferedColor: theme.dividerColor,
                                backgroundColor: Colors.white24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Selected File: ${_selectedVideo!.name}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isAnalyzing ? null : _clearSelectedVideo,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: Icon(Icons.delete_outline, size: 16, color: theme.colorScheme.error),
                        label: Text(
                          "REMOVE VIDEO",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: theme.colorScheme.error),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _runVideoAnalysis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.analytics_outlined, size: 16),
                        label: const Text(
                          "ANALYZE VIDEO",
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
                            "ANALYSIS ERROR / UPLOAD FAILURE",
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
                      "Error description: $_errorMessage\n\nPlease check your network connection and verify that the n8n webhook workflow is active and accessible.",
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
                        pickerCard,
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
                        : _textResponse != null
                            ? _buildPlainTextReport(theme, isDark, _textResponse!)
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
                                    Icon(Icons.video_library_outlined, size: 40, color: Colors.grey),
                                    SizedBox(height: 12),
                                    Text(
                                      "Select or capture video for forensic lip-sync and deepfake evaluation.",
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
              pickerCard,
              if (_isAnalyzing) loadingWidget,
              if (_errorMessage != null) errorWidget,
              if (_analysisResult != null) ...[
                const SizedBox(height: 20),
                _buildAnalysisReport(theme, isDark, _analysisResult!),
              ],
              if (_textResponse != null) ...[
                const SizedBox(height: 20),
                _buildPlainTextReport(theme, isDark, _textResponse!),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlainTextReport(ThemeData theme, bool isDark, String responseText) {
    final accentColor = theme.colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
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
                      "VIDEO ANALYSIS",
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
            child: Text(
              responseText,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, height: 1.5),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAnalysisReport(ThemeData theme, bool isDark, VideoAnalysisResult result) {
    final verdictLower = result.verdict.toLowerCase();
    Color verdictColor;
    IconData verdictIcon;
    if (verdictLower.contains('true') || verdictLower.contains('real') || verdictLower.contains('verified')) {
      verdictColor = const Color(0xFF10B981); // Green
      verdictIcon = Icons.check_circle_outline;
    } else if (verdictLower.contains('fake') || verdictLower.contains('manipulated') || verdictLower.contains('false') || verdictLower.contains('deepfake')) {
      verdictColor = const Color(0xFFEF4444); // Red
      verdictIcon = Icons.cancel_outlined;
    } else {
      verdictColor = const Color(0xFFF59E0B); // Orange/Amber
      verdictIcon = Icons.help_outline_outlined;
    }

    final confidencePercent = result.confidence.toDouble().clamp(0.0, 100.0);
    final deepfakePercent = result.deepfakeProbability.toDouble().clamp(0.0, 100.0);

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
                        "VIDEO FORENSIC REPORT",
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
                            "Verdict: ${result.verdict}",
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
                // 1. Video Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("🎥", style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Video Title",
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.videoTitle,
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

                // 2. Summary
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
                            "Summary",
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            result.summary,
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

                // 3. Main Claim
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
                              result.mainClaim,
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

                // 4. Verdict & Manipulation Detected Card
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: verdictColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: verdictColor.withOpacity(0.15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "✅ Verdict",
                              style: TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              result.verdict,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: verdictColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: result.manipulationDetected
                              ? const Color(0xFFEF4444).withOpacity(0.05)
                              : const Color(0xFF10B981).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: result.manipulationDetected
                                ? const Color(0xFFEF4444).withOpacity(0.15)
                                : const Color(0xFF10B981).withOpacity(0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "⚠ Manipulation Detected",
                              style: TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              result.manipulationDetected ? "DETECTED" : "CLEAN",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: result.manipulationDetected ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. Confidence Score
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

                // 6. Deepfake Probability
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("🤖", style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        const Text(
                          "Deepfake Probability: ",
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${deepfakePercent.round()}%",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: deepfakePercent > 50 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: deepfakePercent / 100.0,
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        color: deepfakePercent > 50 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // 7. Explanation
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
                            result.explanation,
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

                // 8. Suspicious Timestamps
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("⏱", style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Suspicious Timestamps",
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (result.misleadingSegments.isEmpty)
                            const Text(
                              "No suspicious segments detected.",
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            )
                          else
                            ...result.misleadingSegments.map((segment) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: theme.dividerColor),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.schedule, size: 14, color: theme.colorScheme.secondary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            segment.timestamp,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'monospace',
                                              color: theme.colorScheme.secondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            segment.reason,
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // 9. Supporting Sources
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
                          if (result.sources.isEmpty)
                            const Text(
                              "No verified sources listed.",
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: result.sources.map((src) {
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

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 50.0,
                      semanticLabel: 'Play',
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
      ],
    );
  }
}
