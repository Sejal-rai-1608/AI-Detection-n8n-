class MisleadingSegment {
  final String timestamp;
  final String reason;

  const MisleadingSegment({
    required this.timestamp,
    required this.reason,
  });

  factory MisleadingSegment.fromJson(Map<String, dynamic> json) {
    return MisleadingSegment(
      timestamp: json['timestamp'] ?? '',
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'reason': reason,
    };
  }
}

class VideoAnalysisResult {
  final String videoTitle;
  final String summary;
  final String mainClaim;
  final String verdict;
  final int confidence;
  final String explanation;
  final bool manipulationDetected;
  final int deepfakeProbability;
  final List<MisleadingSegment> misleadingSegments;
  final List<String> sources;

  const VideoAnalysisResult({
    required this.videoTitle,
    required this.summary,
    required this.mainClaim,
    required this.verdict,
    required this.confidence,
    required this.explanation,
    required this.manipulationDetected,
    required this.deepfakeProbability,
    required this.misleadingSegments,
    required this.sources,
  });

  factory VideoAnalysisResult.fromJson(Map<String, dynamic> json) {
    // Safe parsing for misleadingSegments
    final List<MisleadingSegment> segments = [];
    final rawMisleading = json['misleadingSegments'] ?? json['misleading_segments'] ?? json['segments'];
    if (rawMisleading is List) {
      for (final s in rawMisleading) {
        if (s is Map<String, dynamic>) {
          segments.add(MisleadingSegment.fromJson(s));
        } else if (s is Map) {
          segments.add(MisleadingSegment.fromJson(Map<String, dynamic>.from(s)));
        }
      }
    }

    // Safe parsing for confidence
    final rawConfidence = json['confidence'];
    int parsedConfidence = 0;
    if (rawConfidence is num) {
      if (rawConfidence <= 1.0 && rawConfidence >= 0.0) {
        parsedConfidence = (rawConfidence * 100).round();
      } else {
        parsedConfidence = rawConfidence.round();
      }
    } else if (rawConfidence is String) {
      final cleaned = rawConfidence.replaceAll('%', '').trim();
      final parsedDouble = double.tryParse(cleaned);
      if (parsedDouble != null) {
        if (parsedDouble <= 1.0 && parsedDouble >= 0.0) {
          parsedConfidence = (parsedDouble * 100).round();
        } else {
          parsedConfidence = parsedDouble.round();
        }
      }
    }

    // Safe parsing for deepfakeProbability
    final rawDeepfake = json['deepfakeProbability'] ?? json['deepfake_probability'] ?? json['deepfake_prob'];
    int parsedDeepfake = 0;
    if (rawDeepfake is num) {
      if (rawDeepfake <= 1.0 && rawDeepfake >= 0.0) {
        parsedDeepfake = (rawDeepfake * 100).round();
      } else {
        parsedDeepfake = rawDeepfake.round();
      }
    } else if (rawDeepfake is String) {
      final cleaned = rawDeepfake.replaceAll('%', '').trim();
      final parsedDouble = double.tryParse(cleaned);
      if (parsedDouble != null) {
        if (parsedDouble <= 1.0 && parsedDouble >= 0.0) {
          parsedDeepfake = (parsedDouble * 100).round();
        } else {
          parsedDeepfake = parsedDouble.round();
        }
      }
    } else {
      // Fallback: derive from verdict
      final verdictStr = (json['verdict'] ?? '').toString().toLowerCase();
      if (verdictStr.contains('fake') || verdictStr.contains('manipulated') || verdictStr.contains('false') || verdictStr.contains('deepfake')) {
        parsedDeepfake = parsedConfidence > 0 ? parsedConfidence : 85;
      } else {
        parsedDeepfake = 15;
      }
    }

    // Safe parsing for sources
    final List<String> parsedSources = [];
    final rawSources = json['sources'];
    if (rawSources is List) {
      for (final src in rawSources) {
        if (src != null) {
          parsedSources.add(src.toString());
        }
      }
    }

    final verdictStr = (json['verdict'] ?? '').toString();
    final verdictLower = verdictStr.toLowerCase();
    
    // Safe parsing for manipulationDetected
    final bool isManipulated = json['manipulationDetected'] ??
        json['manipulation_detected'] ??
        (verdictLower.contains('fake') ||
            verdictLower.contains('manipulated') ||
            verdictLower.contains('false') ||
            verdictLower.contains('deepfake'));

    return VideoAnalysisResult(
      videoTitle: json['videoTitle'] ?? json['video_title'] ?? json['title'] ?? 'Uploaded Video',
      summary: json['summary'] ?? '',
      mainClaim: json['mainClaim'] ?? json['main_claim'] ?? json['summary'] ?? 'AI Video Verification Analysis',
      verdict: verdictStr,
      confidence: parsedConfidence,
      explanation: json['explanation'] ?? json['reason'] ?? '',
      manipulationDetected: isManipulated,
      deepfakeProbability: parsedDeepfake,
      misleadingSegments: segments,
      sources: parsedSources,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoTitle': videoTitle,
      'summary': summary,
      'mainClaim': mainClaim,
      'verdict': verdict,
      'confidence': confidence,
      'explanation': explanation,
      'manipulationDetected': manipulationDetected,
      'deepfakeProbability': deepfakeProbability,
      'misleadingSegments': misleadingSegments.map((s) => s.toJson()).toList(),
      'sources': sources,
    };
  }
}
