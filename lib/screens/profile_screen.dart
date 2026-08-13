import 'package:flutter/material.dart';
import 'package:n8ntrial/models/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifications = true;
  String _activeLanguage = "English";

  @override
  void initState() {
    super.initState();
    appState.addListener(_updateScreen);
  }

  @override
  void dispose() {
    appState.removeListener(_updateScreen);
    super.dispose();
  }

  void _updateScreen() {
    if (mounted) {
      setState(() {});
    }
  }

  void _selectLanguage() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text(
            "Select Language",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ["English", "Hindi", "Spanish"].map((lang) {
              return ListTile(
                title: Text(lang, style: const TextStyle(fontSize: 14)),
                trailing: _activeLanguage == lang
                    ? const Icon(Icons.check, color: Color(0xFF4361EE))
                    : null,
                onTap: () {
                  setState(() {
                    _activeLanguage = lang;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Language switched to $lang")),
                  );
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile header
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4361EE).withOpacity(0.15),
                  border: Border.all(
                    color: const Color(0xFF4361EE),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.person,
                  size: 30,
                  color: Color(0xFF4361EE),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appState.currentUser?['name'] ?? "Sejal Rai",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appState.currentUser?['email'] ?? "sejal.rai@example.com",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats grid
          Row(
            children: [
              Expanded(child: _buildProfileStatCard("Total Reports", "145")),
              const SizedBox(width: 10),
              Expanded(child: _buildProfileStatCard("Accuracy", "97%")),
              const SizedBox(width: 10),
              Expanded(
                child: _buildProfileStatCard("Member Since", "Jan 2024"),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Pro member card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE2AD32), Color(0xFFB8860B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pro Member",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Unlimited checks and advanced features",
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Settings Section
          Text(
            "Settings",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                _buildSwitchRow(
                  "Dark Mode",
                  Icons.dark_mode_outlined,
                  appState.isDarkMode,
                  (v) {
                    appState.toggleDarkMode(v);
                  },
                ),
                const Divider(height: 1),
                _buildArrowRow(
                  "Language",
                  Icons.language_outlined,
                  _activeLanguage,
                  _selectLanguage,
                ),
                const Divider(height: 1),
                _buildSwitchRow(
                  "Notifications",
                  Icons.notifications_none_outlined,
                  _notifications,
                  (v) {
                    setState(() {
                      _notifications = v;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Notifications ${v ? 'enabled' : 'disabled'}",
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildArrowRow(
                  "Privacy & Security",
                  Icons.lock_outline,
                  "",
                  () {},
                ),
                const Divider(height: 1),
                _buildArrowRow("Help & Support", Icons.help_outline, "", () {}),
                const Divider(height: 1),
                _buildArrowRow(
                  "Admin & n8n Panel",
                  Icons.admin_panel_settings_outlined,
                  "System status",
                  () {
                    appState.setDashboardIndex(5);
                  },
                ),
                const Divider(height: 1),
                _buildArrowRow(
                  "About TruthLens AI",
                  Icons.info_outline,
                  "v1.0.0",
                  () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          ElevatedButton(
            onPressed: () {
              appState.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF2A54).withOpacity(0.1),
              foregroundColor: const Color(0xFFFF2A54),
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFFF2A54), width: 1),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Logout",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStatCard(String title, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChange,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChange,
            activeColor: const Color(0xFF4361EE),
          ),
        ],
      ),
    );
  }

  Widget _buildArrowRow(
    String label,
    IconData icon,
    String value,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            if (value.isNotEmpty)
              Text(
                value,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
