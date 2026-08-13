import 'package:flutter/material.dart';
import 'package:n8ntrial/models/app_state.dart';
import 'package:n8ntrial/tabs/news_analyzer_tab.dart';
import 'package:n8ntrial/tabs/image_analyzer_tab.dart';
import 'package:n8ntrial/tabs/url_analyzer_tab.dart';
import 'package:n8ntrial/tabs/video_analyzer_tab.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> with SingleTickerProviderStateMixin {
  late TabController _verifyTabController;

  @override
  void initState() {
    super.initState();
    _verifyTabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: appState.initialVerifyTabIndex,
    );
    appState.verifyTabController = _verifyTabController;
  }

  @override
  void dispose() {
    if (appState.verifyTabController == _verifyTabController) {
      appState.verifyTabController = null;
    }
    _verifyTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          color: theme.colorScheme.surface,
          child: TabBar(
            controller: _verifyTabController,
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3,
            labelColor: isDark ? Colors.white : Colors.black87,
            unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[600],
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace'),
            tabs: const [
              Tab(text: "News Scan"),
              Tab(text: "Image Forensics"),
              Tab(text: "URL Analyzer"),
              Tab(text: "Video Verification"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _verifyTabController,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              NewsAnalyzerTab(),
              ImageAnalyzerTab(),
              UrlAnalyzerTab(),
              VideoAnalyzerTab(),
            ],
          ),
        ),
      ],
    );
  }
}
