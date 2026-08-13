import 'package:flutter/material.dart';
import 'package:n8ntrial/models/app_state.dart';

class BacktrackTab extends StatefulWidget {
  const BacktrackTab({super.key});

  @override
  State<BacktrackTab> createState() => _BacktrackTabState();
}

class _BacktrackTabState extends State<BacktrackTab> {
  final TextEditingController _searchController = TextEditingController();
  bool _isBacktracking = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = appState.currentBacktrackTitle;
    appState.onStartBacktrackSearch = _handleBacktrackRequested;
    
    if (appState.currentBacktrackTitle.isNotEmpty && appState.activeBacktrackReport != null) {
      _runBacktrackSearch();
    }
  }

  @override
  void dispose() {
    if (appState.onStartBacktrackSearch == _handleBacktrackRequested) {
      appState.onStartBacktrackSearch = null;
    }
    _searchController.dispose();
    super.dispose();
  }

  void _handleBacktrackRequested() {
    if (!mounted) return;
    setState(() {
      _searchController.text = appState.currentBacktrackTitle;
    });
    _runBacktrackSearch();
  }

  void _runBacktrackSearch() async {
    if (!mounted) return;
    setState(() {
      _isBacktracking = true;
    });

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    setState(() {
      _isBacktracking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final report = appState.activeBacktrackReport;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Tracker Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF101726),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Enter query or trace link to backtrack origin",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF080C16),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF1E293B)),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: "Enter viral post URL...",
                            hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isBacktracking ? null : _runBacktrackSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4361EE),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("TRACE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                )
              ],
            ),
          ),

          if (_isBacktracking) ...[
            Container(
              height: 300,
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4361EE)),
                  SizedBox(height: 16),
                  Text(
                    "RESOLVING REVERSE REFERRAL LOGS...",
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            )
          ] else if (report != null) ...[
            const SizedBox(height: 20),
            // Original Source Card
            const Text(
              "Original Source",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF101726),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF2A54),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      report.originalLogo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.originalSource,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Published: ${report.firstPublishedDate}",
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
                    onPressed: () {},
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Spread Timeline Graph
            const Text(
              "Spread Timeline",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF101726),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                children: report.timelineOfReposts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == report.timelineOfReposts.length - 1;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline line & circle
                      Column(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == 0 ? const Color(0xFF2EC4B6) : const Color(0xFF4361EE),
                            ),
                            child: Icon(
                              index == 0 ? Icons.radar : Icons.hub_outlined,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 45,
                              color: const Color(0xFF1E293B),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Text info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item["account"] ?? "",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item["post"] ?? "",
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item["time"] ?? "",
                              style: TextStyle(fontSize: 9, color: Colors.grey[500], fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Credibility Score Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF101726),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Credibility Score",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70),
                      ),
                      Text(
                        "95/100",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2EC4B6), fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.95,
                      backgroundColor: Color(0xFF080C16),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2EC4B6)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Fact Check Articles list
            const Text(
              "Fact Check Articles",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            ...report.factCheckArticles.map((article) {
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
                    Text(
                      article,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                    const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                  ],
                ),
              );
            }).toList(),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
              child: const Column(
                children: [
                  Icon(Icons.radar, size: 40, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    "No Active Backtrack Trace Loaded",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0x8AFFFFFF)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Verify a fake item, then request backtrack to see source logs.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }
}
