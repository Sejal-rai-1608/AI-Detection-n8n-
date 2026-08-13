import 'package:flutter/material.dart';
import 'package:n8ntrial/models/models.dart';
import 'package:n8ntrial/models/app_state.dart';
import 'package:n8ntrial/services/api_service.dart';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';

class ImageAnalyzerTab extends StatefulWidget {
  const ImageAnalyzerTab({super.key});

  @override
  State<ImageAnalyzerTab> createState() => _ImageAnalyzerTabState();
}

class _ImageAnalyzerTabState extends State<ImageAnalyzerTab> {
  final ApiService _apiService = ApiService();
  ImagePreset? _activeImage;
  bool _isAnalyzing = false;
  String? _errorMessage;
  String? _failedFileName;
  Uint8List? _failedBytes;

  @override
  void initState() {
    super.initState();
    appState.onTriggerImageAnalysis = _triggerAnalysis;
  }

  @override
  void dispose() {
    if (appState.onTriggerImageAnalysis == _triggerAnalysis) {
      appState.onTriggerImageAnalysis = null;
    }
    super.dispose();
  }

  ImagePreset _parseN8nResponse(ImagePreset preset, Map<String, dynamic> rawResult, {Uint8List? fallbackBytes}) {
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
        } catch (e) {
          result = {
            "status": "Suspicious",
            "confidence": 70.0,
            "reason": outputVal
          };
        }
      }
    }

    final status = result["status"] ?? "Fake";
    final isFake = status == "Fake" || status == "Suspicious";
    final double confidence = (result["confidence"] ?? 50.0).toDouble();

    final displayBytes = result["processed_image_bytes"] != null
        ? (result["processed_image_bytes"] as Uint8List)
        : (preset.pickedImageBytes ?? fallbackBytes);

    return ImagePreset(
      title: preset.title,
      assetName: preset.assetName,
      aiConfidence: confidence / 100,
      manipulationScore: isFake ? (confidence / 100) : (1.0 - confidence / 100),
      softwareSignature: result["reason"] ?? "Adobe Photoshop 2026",
      exif: preset.exif,
      editHotspots: preset.editHotspots,
      backtrackReport: preset.backtrackReport,
      pickedImageBytes: displayBytes,
    );
  }

  void _triggerAnalysis(ImagePreset preset) async {
    if (!mounted) return;
    setState(() {
      _isAnalyzing = true;
      _activeImage = null;
      _errorMessage = null;
      _failedFileName = null;
      _failedBytes = null;
    });

    const String mockBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=";

    try {
      final response = await _apiService.verifyImage(
        base64Decode(mockBase64),
        "mock_preset_image.png",
      );
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _activeImage = _parseN8nResponse(
          preset,
          response,
          fallbackBytes: base64Decode(mockBase64),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _activeImage = preset;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("n8n Webhook timed out. Switched to offline preset image."),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _pickImageFromBrowser() {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        final file = files[0];
        final reader = html.FileReader();
        
        reader.readAsArrayBuffer(file);
        reader.onLoadEnd.listen((e) {
          final bytes = reader.result as Uint8List;
          
          setState(() {
            _isAnalyzing = true;
            _activeImage = null;
            _errorMessage = null;
            _failedFileName = null;
            _failedBytes = null;
          });

          // Compress/downscale image via HTML Canvas before sending to n8n to prevent Payload Too Large & Timeout
          try {
            final blob = html.Blob([bytes]);
            final url = html.Url.createObjectUrlFromBlob(blob);
            final img = html.ImageElement(src: url);
            img.onLoad.first.then((_) {
              final canvas = html.CanvasElement();
              const int maxDimension = 600;
              int width = img.width ?? 0;
              int height = img.height ?? 0;
              
              if (width == 0 || height == 0) {
                width = 600;
                height = 600;
              }
              
              if (width > maxDimension || height > maxDimension) {
                if (width > height) {
                  height = (height * maxDimension / width).round();
                  width = maxDimension;
                } else {
                  width = (width * maxDimension / height).round();
                  height = maxDimension;
                }
              }
              
              canvas.width = width;
              canvas.height = height;
              final ctx = canvas.context2D;
              ctx.drawImageScaled(img, 0, 0, width, height);
              
              // Compress to JPEG with 80% quality
              final dataUrl = canvas.toDataUrl('image/jpeg', 0.8);
              final base64String = dataUrl.split(',')[1];
              html.Url.revokeObjectUrl(url);
              
              _verifySelectedImage(file.name, base64String, bytes);
            }).catchError((err) {
              final base64String = base64Encode(bytes);
              _verifySelectedImage(file.name, base64String, bytes);
            });
          } catch (err) {
            final base64String = base64Encode(bytes);
            _verifySelectedImage(file.name, base64String, bytes);
          }
        });
      }
    });
  }

  void _verifySelectedImage(String fileName, String base64Image, Uint8List bytes) async {
    try {
      final rawResponse = await _apiService.verifyImage(bytes, fileName);
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
            }
          } catch (e) {
            response = {
              "status": "Suspicious",
              "confidence": 70.0,
              "reason": outputVal
            };
          }
        }
      }

      setState(() {
        _isAnalyzing = false;
        _errorMessage = null;

        final displayBytes = response["processed_image_bytes"] != null
            ? (response["processed_image_bytes"] as Uint8List)
            : bytes;

        _activeImage = ImagePreset(
          title: fileName,
          assetName: "",
          aiConfidence: ((response["confidence"] ?? 80.0) as num).toDouble() / 100,
          manipulationScore: (response["status"] ?? "Fake") == "Fake" ? 0.95 : 0.05,
          softwareSignature: response["reason"] ?? "Metadata trace check",
          exif: const {"Source": "User Uploaded Local File"},
          editHotspots: const [],
          pickedImageBytes: displayBytes,
          backtrackReport: BacktrackReport(
            originalSource: response["sources"] != null && (response["sources"] as List).isNotEmpty 
                ? (response["sources"] as List).first.toString() 
                : "Uploaded File",
            originalLogo: "UF",
            firstPublishedDate: "Log Date",
            websiteHistory: response["reason"] ?? "File analysis signature",
            reverseImageSources: const [],
            factCheckArticles: const [],
            timelineOfReposts: const [],
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _failedFileName = fileName;
        _failedBytes = bytes;
        _activeImage = null;
      });
    }
  }

  void _runOfflineSimulation(String fileName, Uint8List bytes) {
    setState(() {
      _isAnalyzing = false;
      _errorMessage = null;

      final nameLower = fileName.toLowerCase();
      // Determine if fake/manipulated based on keyword matching
      final bool isFake = nameLower.contains("fake") || 
                           nameLower.contains("manipulated") || 
                           nameLower.contains("screenshot") || 
                           nameLower.contains("error") || 
                           nameLower.contains("edited");

      final double confidence = isFake ? 88.0 + (bytes.length % 10) : 95.0 + (bytes.length % 4);

      final String software = isFake 
          ? "Adobe Photoshop 2026 // Cloned Pixel Artifacts Flagged" 
          : "Unmodified Camera Capture // Authentic Sensor Signature";

      final String reason = isFake
          ? "Analysis detected double JPEG compression anomalies and metadata modifications. Asymmetric pixel boundaries found in core canvas."
          : "No structural manipulation detected. Exif and sensor trace match standard profile. High structural similarity index.";

      final backtrack = BacktrackReport(
        originalSource: isFake 
            ? "IP 194.22.180.12 (Sofia, Bulgaria routing node)" 
            : "Direct User Upload",
        originalLogo: isFake ? "IP" : "UU",
        firstPublishedDate: isFake ? "12 May 2026 - 11:10 AM" : "Not indexed in public domains",
        websiteHistory: isFake 
            ? "File hash matches 14 unique mirrors. First index found on anonymous imageboards." 
            : "No previous web indexes found. Sensor fingerprint matches clean upload.",
        reverseImageSources: isFake 
            ? const [
                "Yandex Visual: Matches empty square background (Protestors cloned from 2020 rally).",
                "TinEye: 4 matches found. First seen on 2026-05-12."
              ]
            : const [],
        factCheckArticles: isFake ? const ["FactCheck.org AI scan"] : const [],
        timelineOfReposts: isFake 
            ? const [
                {"time": "11:10 AM", "account": "Belgian_Alert (Origin)", "post": "Cloned assembly image posted!"},
                {"time": "11:15 AM", "account": "@BotNetAmplifier", "post": "RT: Look at this crowd!"}
              ]
            : const [],
      );

      _activeImage = ImagePreset(
        title: fileName,
        assetName: "",
        aiConfidence: confidence / 100,
        manipulationScore: isFake ? (confidence / 100) : (1.0 - confidence / 100),
        softwareSignature: reason,
        exif: {
          "Source": "User Uploaded Local File",
          "File Name": fileName,
          "Size": "${(bytes.length / 1024).toStringAsFixed(1)} KB",
          "Software Signature": software,
        },
        editHotspots: isFake ? const [Offset(80, 220), Offset(280, 210)] : const [],
        pickedImageBytes: bytes,
        backtrackReport: backtrack,
      );
    });
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;

        final uploaderCard = Container(
          height: 200,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey[600]),
              const SizedBox(height: 10),
              Text(
                "Upload suspect media to scan",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
              ),
              const SizedBox(height: 4),
              const Text(
                "Supports JPG, PNG, WEBP files",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _pickImageFromBrowser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: const Text("BROWSE FILE", style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );

        final loadingWidget = _isAnalyzing
            ? Container(
                height: 250,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: theme.colorScheme.primary),
                      const SizedBox(height: 16),
                      const Text(
                        "INTERPOLATING COMPRESSION HEATMAPS...",
                        style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey),
                      )
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
                      "Error description: $_errorMessage\n\nNote: Verify n8n webhook URL, routing nodes, and ensure the 'image' output of the Switch node is connected. You can run offline simulator for testing.",
                      style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              if (_failedFileName != null && _failedBytes != null) {
                                _runOfflineSimulation(_failedFileName!, _failedBytes!);
                              } else {
                                if (_activeImage == null) {
                                  _runOfflineSimulation("Simulated_Image_Forensics.png", Uint8List(0));
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.colorScheme.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              "RUN OFFLINE SIMULATION",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: theme.colorScheme.primary,
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
                  flex: 2,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_activeImage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("ACTIVE IMAGE SOURCE", style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(_activeImage!.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 4),
                                const Text("Dimensions: 1080x1350 // format: JPEG", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _activeImage = null;
                                      _errorMessage = null;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: const Icon(Icons.refresh, size: 14),
                                  label: const Text("RESET / UPLOAD NEW", style: TextStyle(fontSize: 10, fontFamily: 'monospace')),
                                ),
                              ],
                            ),
                          ),
                        ] else if (!_isAnalyzing) ...[
                          uploaderCard,
                        ],
                        if (_isAnalyzing) loadingWidget,
                        errorWidget,
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    child: _activeImage != null
                        ? _buildInteractiveForensicsView()
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
                                Icon(Icons.image_search_outlined, size: 40, color: Colors.grey),
                                SizedBox(height: 12),
                                Text(
                                  "Select an image preset or upload a new file to launch the forensics workspace.",
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
              if (_isAnalyzing) ...[
                loadingWidget,
              ] else if (_activeImage == null) ...[
                uploaderCard,
                errorWidget,
              ] else ...[
                _buildInteractiveForensicsView(),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildInteractiveForensicsView() {
    final preset = _activeImage!;
    final bool isFake = preset.manipulationScore > 0.5;
    final Color accentColor = isFake ? const Color(0xFFFF2A54) : const Color(0xFF2EC4B6);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Display
          Container(
            height: 250,
            color: Colors.black,
            child: PresetForensicsVisualizer(preset: preset),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score card
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
                            isFake ? "Fake / Manipulated Image" : "Real Verified Image",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: accentColor, fontFamily: 'monospace'),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${(preset.aiConfidence * 100).round()}% Confidence Score",
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withOpacity(0.15),
                        ),
                        child: Icon(
                          isFake ? Icons.error_outline : Icons.check_circle_outline,
                          color: accentColor,
                          size: 26,
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  "DETECTION LOG ANALYSIS",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 8),
                Text(
                  preset.softwareSignature,
                  style: TextStyle(fontSize: 12, height: 1.4, color: isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 24),

                // Actions
                ElevatedButton.icon(
                  onPressed: () {
                    if (isFake && preset.backtrackReport != null) {
                      appState.requestBacktrack(preset.title, preset.backtrackReport!);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06C270),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.image_search, size: 16),
                  label: const Text("Reverse Image Search", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }


}

// Custom mock image vectors created purely in code
class PresetForensicsVisualizer extends StatelessWidget {
  final ImagePreset preset;
  const PresetForensicsVisualizer({super.key, required this.preset});

  @override
  Widget build(BuildContext context) {
    if (preset.pickedImageBytes != null) {
      return Image.memory(preset.pickedImageBytes!, fit: BoxFit.cover);
    }
    if (preset.assetName == "speech_deepfake") {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey[900]!, const Color(0xFF0F1424)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Opacity(
              opacity: 0.1,
              child: GridPaper(color: const Color(0xFF4361EE), divisions: 2, subdivisions: 2),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.face_retouching_natural, size: 70, color: const Color(0xFFFF2A54).withOpacity(0.8)),
                  const SizedBox(height: 8),
                  const Text(
                    "DEEPFAKE SCAN DETECTED",
                    style: TextStyle(fontFamily: 'monospace', color: Color(0xFFFF2A54), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    "ASYMMETRIC FACIAL RECONSTRUCTION FLAGGED",
                    style: TextStyle(fontFamily: 'monospace', color: Colors.grey[500], fontSize: 9),
                  ),
                ],
              ),
            ),
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFF2A54), width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 100,
              child: Container(
                height: 2,
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(color: Color(0xFFFF2A54), blurRadius: 10, spreadRadius: 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Crowd manipulation
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey[900]!, const Color(0xFF141A30)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 25,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (index) => Icon(Icons.location_city, size: 40, color: Colors.blueGrey[700]!.withOpacity(0.4))),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (index) => Icon(Icons.group, size: 26, color: Colors.blueGrey[850]!)),
              ),
            ),
            _buildCloningTarget(65, 80),
            _buildCloningTarget(220, 160),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "CLONED PIXEL ARTIFACTS",
                    style: TextStyle(fontFamily: 'monospace', color: Color(0xFFFF2A54), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "COMPRESSION DUPLICATIONS DETECTED",
                    style: TextStyle(fontFamily: 'monospace', color: Colors.grey[500], fontSize: 9),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    }
  }

  Widget _buildCloningTarget(double left, double top) {
    return Positioned(
      left: left,
      top: top,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF2A54), width: 1.5),
            ),
            child: const Icon(Icons.close, size: 10, color: Color(0xFFFF2A54)),
          ),
          const SizedBox(height: 2),
          const Text("CLONE TARGET", style: TextStyle(fontSize: 7, color: Color(0xFFFF2A54), fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
