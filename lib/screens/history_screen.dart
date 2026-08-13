import 'package:flutter/material.dart';
import 'package:n8ntrial/models/models.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _activeFilter = "All";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter & Search Logic
    List<HistoryItem> filteredList = historyDatabase.where((item) {
      // Category filter
      bool matchesCategory = true;
      if (_activeFilter == "News") {
        matchesCategory = item.category.contains("News");
      } else if (_activeFilter == "Images") {
        matchesCategory = item.category.contains("Image");
      } else if (_activeFilter == "URLs") {
        matchesCategory = item.category.contains("URL") || item.category.contains("Domain");
      }

      // Search filter
      bool matchesSearch = item.title.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();

    // Group items by Date
    List<HistoryItem> todayItems = filteredList.where((item) => item.dateGroup == "Today").toList();
    List<HistoryItem> yesterdayItems = filteredList.where((item) => item.dateGroup == "Yesterday").toList();
    List<HistoryItem> olderItems = filteredList.where((item) => item.dateGroup == "Older").toList();

    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: theme.colorScheme.surface,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      hintText: "Search reports archive...",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = "";
                      });
                    },
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  )
              ],
            ),
          ),
        ),

        // Filter bar
        Container(
          padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
          color: theme.colorScheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ["All", "News", "Images", "URLs"].map((filter) {
              final isSelected = _activeFilter == filter;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _activeFilter = filter;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // History list body
        Expanded(
          child: filteredList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_toggle_off_outlined, size: 48, color: theme.dividerColor),
                      const SizedBox(height: 12),
                      const Text(
                        "No verification history found",
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (todayItems.isNotEmpty) ...[
                      _buildGroupHeader("TODAY'S SCAN DOSSIER"),
                      ...todayItems.map((item) => _buildHistoryTile(item, theme, isDark)),
                    ],
                    if (yesterdayItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildGroupHeader("YESTERDAY'S SCAN DOSSIER"),
                      ...yesterdayItems.map((item) => _buildHistoryTile(item, theme, isDark)),
                    ],
                    if (olderItems.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildGroupHeader("ARCHIVE LOGS"),
                      ...olderItems.map((item) => _buildHistoryTile(item, theme, isDark)),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildGroupHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[500],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildHistoryTile(HistoryItem item, ThemeData theme, bool isDark) {
    // Redesign indicators to use Coral Red (#EF4444) for Fake, Emerald Green (#10B981) for Real, Amber (#F59E0B) for Suspicious
    final bool isReal = item.trustScore > 75;
    final bool isFake = item.trustScore < 45;
    
    final Color badgeColor = isReal 
        ? const Color(0xFF10B981) 
        : (isFake ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));
        
    final Color badgeBg = badgeColor.withOpacity(0.08);

    IconData itemIcon;
    Color iconColor;
    if (item.category.contains("Image")) {
      itemIcon = Icons.image_outlined;
      iconColor = const Color(0xFF10B981);
    } else if (item.category.contains("URL") || item.category.contains("Domain")) {
      itemIcon = Icons.link_outlined;
      iconColor = const Color(0xFFF59E0B);
    } else {
      itemIcon = Icons.article_outlined;
      iconColor = const Color(0xFF4338CA);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          // Left Category Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              itemIcon,
              color: iconColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),

          // Title & Category details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.category.toUpperCase(),
                  style: TextStyle(fontSize: 9, color: Colors.grey[500], fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Trust score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withOpacity(0.2)),
            ),
            child: Text(
              "TRUST: ${item.trustScore}%",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: badgeColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
