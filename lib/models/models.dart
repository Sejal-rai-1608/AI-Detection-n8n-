import 'package:flutter/material.dart';
import 'dart:typed_data';

class BacktrackReport {
  final String originalSource;
  final String originalLogo; // e.g. placeholder initials or symbol
  final String firstPublishedDate;
  final String websiteHistory;
  final List<String> reverseImageSources;
  final List<String> factCheckArticles;
  final List<Map<String, String>> timelineOfReposts;

  const BacktrackReport({
    required this.originalSource,
    required this.originalLogo,
    required this.firstPublishedDate,
    required this.websiteHistory,
    required this.reverseImageSources,
    required this.factCheckArticles,
    required this.timelineOfReposts,
  });
}

class NewsPreset {
  final String title;
  final String content;
  final String source;
  final double score;
  final String category;
  final List<String> flaggedPhrases;
  final Map<String, double> metrics;
  final BacktrackReport? backtrackReport;
  final String? explanation;
  final List<String>? redFlags;
  final List<String>? supportingSources;
  final String? rawResponse;

  const NewsPreset({
    required this.title,
    required this.content,
    required this.source,
    required this.score,
    required this.category,
    required this.flaggedPhrases,
    required this.metrics,
    this.backtrackReport,
    this.explanation,
    this.redFlags,
    this.supportingSources,
    this.rawResponse,
  });
}

class ImagePreset {
  final String title;
  final String assetName;
  final double aiConfidence;
  final double manipulationScore;
  final String softwareSignature;
  final Map<String, String> exif;
  final List<Offset> editHotspots;
  final BacktrackReport? backtrackReport;
  final Uint8List? pickedImageBytes;

  const ImagePreset({
    required this.title,
    required this.assetName,
    required this.aiConfidence,
    required this.manipulationScore,
    required this.softwareSignature,
    required this.exif,
    required this.editHotspots,
    this.backtrackReport,
    this.pickedImageBytes,
  });
}

class HistoryItem {
  final String title;
  final String category;
  final int trustScore;
  final bool isFake;
  final String dateGroup; // Today, Yesterday, Older

  const HistoryItem({
    required this.title,
    required this.category,
    required this.trustScore,
    required this.isFake,
    required this.dateGroup,
  });
}

class AlertItem {
  final String title;
  final String time;

  const AlertItem({required this.title, required this.time});
}

// Preset Data lists with detailed backtracking profiles matching TruthLens screenshots
final List<AlertItem> alertDatabase = [
  const AlertItem(title: "Fake IPL Giveaway link circulating", time: "2 hours ago"),
  const AlertItem(title: "Fake Govt Job Recruitment Notice", time: "5 hours ago"),
  const AlertItem(title: "Fake WhatsApp message on currency change", time: "Yesterday"),
];

final List<HistoryItem> historyDatabase = [
  const HistoryItem(title: "Isro launched astronauts successfully", category: "Real News", trustScore: 92, isFake: false, dateGroup: "Today"),
  const HistoryItem(title: "Flood in Mumbai city drone images", category: "Real News", trustScore: 98, isFake: false, dateGroup: "Today"),
  const HistoryItem(title: "WhatsApp image forward on new tax", category: "Fake Image", trustScore: 96, isFake: true, dateGroup: "Today"),
  const HistoryItem(title: "PM launch scheme for free devices", category: "Real News", trustScore: 97, isFake: false, dateGroup: "Yesterday"),
  const HistoryItem(title: "Earth from Mars satellite photo", category: "Real Image", trustScore: 94, isFake: false, dateGroup: "Yesterday"),
  const HistoryItem(title: "Free iPhone giveaway link", category: "Fake News", trustScore: 91, isFake: true, dateGroup: "Older"),
  const HistoryItem(title: "Job vacancy notification in Rail Corp", category: "Real News", trustScore: 95, isFake: false, dateGroup: "Older"),
];

final List<NewsPreset> newsDatabase = [
  const NewsPreset(
    title: "Secret Water Additives Control Public Mood, Leaked Memo Claims",
    content: "An anonymous source from the Department of Hydrology leaked a document proving secret mood-altering compounds are added to municipal reservoirs. The memo suggests it controls anxiety and increases compliance among 85% of urban citizens. Official agencies denied the claims, calling them baseless.",
    source: "Hydrology-Leaks-Anonymous (Blog)",
    score: 18.0,
    category: "Conspiracy",
    flaggedPhrases: ["secret mood-altering", "department of hydrology leaked", "increases compliance", "proving secret"],
    metrics: {"Sensationalism": 0.92, "Linguistic Bias": 0.85, "Fact-Check Match": 0.08},
    backtrackReport: BacktrackReport(
      originalSource: "Telegram Channel 'LeakZone' (Anonymous Admin, St. Petersburg Server Pool)",
      originalLogo: "LZ",
      firstPublishedDate: "12 Jan 2026 - 10:30 AM",
      websiteHistory: "Domain registered 4 days ago. Hidden WHOIS records. Flagged for malware distribution & low credibility score (12/100).",
      reverseImageSources: [],
      factCheckArticles: [
        "Alt News",
        "BoomLive",
        "PIB Fact Check",
      ],
      timelineOfReposts: [
        {"time": "10:30 AM", "account": "LeakZone (Origin)", "post": "Leaked documents show mood controls inside water grid!"},
        {"time": "11:15 AM", "account": "@SofiaBotNet (Amplifier)", "post": "RT: Everyone needs to see this! #WaterConspiracy"},
        {"time": "01:40 PM", "account": "@TruthSeeker99 (Influencer)", "post": "Is this real? Can anyone verify? [Link]"},
        {"time": "03:20 PM", "account": "ExpressNews Portal (Website)", "post": "BREAKING: Viral claims of chemical additives inside municipal lines."},
      ],
    ),
  ),
  const NewsPreset(
    title: "Global Temperature Records Broken 3rd Month in a Row",
    content: "Meteorological stations worldwide reported temperatures averaging 1.48°C above historical levels. Satellite data confirms the anomaly, matching warnings published by NASA and the World Climate Consortium. Independent data validates the trends.",
    source: "Global Meteorological Center",
    score: 94.0,
    category: "Science",
    flaggedPhrases: [],
    metrics: {"Sensationalism": 0.15, "Linguistic Bias": 0.05, "Fact-Check Match": 0.98},
  ),
];

final List<ImagePreset> imageDatabase = [
  const ImagePreset(
    title: "Politician Deepfake Endorsement",
    assetName: "speech_deepfake",
    aiConfidence: 0.94,
    manipulationScore: 0.88,
    softwareSignature: "DeepFaceLab V2 / StyleGAN3",
    exif: {
      "Camera Model": "N/A - Virtual Render",
      "Software": "FFmpeg + Python3",
      "Created Date": "2026-07-10 14:22:11",
      "GPS Location": "Undefined",
    },
    editHotspots: [Offset(120, 100), Offset(180, 110), Offset(150, 140)],
    backtrackReport: BacktrackReport(
      originalSource: "Telegram Channel 'LeakZone' (Anonymous Admin, St. Petersburg Server Pool)",
      originalLogo: "LZ",
      firstPublishedDate: "10 Jan 2026 - 02:20 PM",
      websiteHistory: "File hash matches 14 unique mirrors. First index found on anonymous imageboards.",
      reverseImageSources: [
        "Google Images: Matches official press conference frame from 2026-02-14 (Original facial features unchanged)",
        "TinEye: 4 matches found. First seen on 2026-07-10.",
      ],
      factCheckArticles: [
        "Reuters Fact Check",
        "LeadStories AI scan",
      ],
      timelineOfReposts: [
        {"time": "02:20 PM", "account": "LeakZone (Telegram)", "post": "STUNNING: Endorsement clip leaked!"},
        {"time": "02:22 PM", "account": "@BotAmplifier_1", "post": "RT: Politician says what we all think! [Video]"},
        {"time": "02:30 PM", "account": "@ViralBuzzHub", "post": "Huge political endorsement shifts election dynamics?"},
      ],
    ),
  ),
  const ImagePreset(
    title: "Manipulated Protest Assembly",
    assetName: "crowd_manipulation",
    aiConfidence: 0.15,
    manipulationScore: 0.78,
    softwareSignature: "Adobe Photoshop 24.1 (Windows)",
    exif: {
      "Camera Model": "Canon EOS R5",
      "Software": "Adobe Photoshop 2026",
      "Created Date": "2026-05-12 11:05:30",
      "GPS Location": "40.7128° N, 74.0060° W",
    },
    editHotspots: [Offset(80, 220), Offset(280, 210), Offset(220, 250)],
    backtrackReport: BacktrackReport(
      originalSource: "IP 194.22.180.12 (Sofia, Bulgaria routing node)",
      originalLogo: "IP",
      firstPublishedDate: "12 May 2026 - 11:10 AM",
      websiteHistory: "Hosting server associated with coordinated influence networks.",
      reverseImageSources: [
        "Yandex Visual: Matches background of empty square in Brussels (Protestors cloned from 2020 rally).",
      ],
      factCheckArticles: [
        "FactCheck.org",
      ],
      timelineOfReposts: [
        {"time": "11:10 AM", "account": "Belgian_Alert (Origin)", "post": "TENS of thousands gather outside parliament right now!"},
        {"time": "11:12 AM", "account": "@SofiaBotNet (Amplifier)", "post": "RT: Look at this massive crowd! #StandUp"},
        {"time": "11:35 AM", "account": "@GlobalNewsFeed", "post": "Reports of protest gather attention online."},
      ],
    ),
  ),
];

class BacktrackNode {
  final String id;
  final String label;
  final String ip;
  final String location;
  final String time;
  final double botProbability;
  final Offset position;
  final List<String> connections;
  final bool isOrigin;

  const BacktrackNode({
    required this.id,
    required this.label,
    required this.ip,
    required this.location,
    required this.time,
    required this.botProbability,
    required this.position,
    required this.connections,
    this.isOrigin = false,
  });
}

class UrlAnalysisResult {
  final String articleTitle;
  final String mainClaim;
  final String verdict;
  final int confidence;
  final String explanation;
  final List<String> sources;
  final String category;
  final String recommendation;

  const UrlAnalysisResult({
    required this.articleTitle,
    required this.mainClaim,
    required this.verdict,
    required this.confidence,
    required this.explanation,
    required this.sources,
    required this.category,
    required this.recommendation,
  });

  factory UrlAnalysisResult.fromJson(Map<String, dynamic> json) {
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

    return UrlAnalysisResult(
      articleTitle: json['articleTitle'] ?? '',
      mainClaim: json['mainClaim'] ?? '',
      verdict: json['verdict'] ?? '',
      confidence: parsedConfidence,
      explanation: json['explanation'] ?? '',
      sources: List<String>.from(json['sources'] ?? []),
      category: json['category'] ?? '',
      recommendation: json['recommendation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'articleTitle': articleTitle,
      'mainClaim': mainClaim,
      'verdict': verdict,
      'confidence': confidence,
      'explanation': explanation,
      'sources': sources,
      'category': category,
      'recommendation': recommendation,
    };
  }
}


