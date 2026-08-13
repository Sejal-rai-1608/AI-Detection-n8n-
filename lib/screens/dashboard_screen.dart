import 'package:flutter/material.dart';
import 'package:n8ntrial/models/app_state.dart';
import 'package:n8ntrial/screens/home_screen.dart';
import 'package:n8ntrial/screens/verify_screen.dart';
import 'package:n8ntrial/screens/history_screen.dart';
import 'package:n8ntrial/screens/insights_screen.dart';
import 'package:n8ntrial/screens/profile_screen.dart';
import 'package:n8ntrial/screens/admin_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    appState.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    appState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 750;

    if (isWide) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Row(
          children: [
            // Side navigation panel (Notion/Gemini split layout)
            Container(
              width: 220,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(right: BorderSide(color: theme.dividerColor, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  // Logo/Brand block
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 24),
                        const SizedBox(width: 10),
                        const Text(
                          "TruthLens AI",
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Navigation Items
                  _buildSideNavItem(0, Icons.home_outlined, "Home"),
                  _buildSideNavItem(1, Icons.verified_user_outlined, "Verify Panel"),
                  _buildSideNavItem(2, Icons.history, "Audit History"),
                  _buildSideNavItem(3, Icons.bar_chart, "Insights"),
                  _buildSideNavItem(4, Icons.person_outline, "Profile Info"),
                  const Spacer(),
                  // Admin Console
                  _buildSideNavItem(5, Icons.admin_panel_settings_outlined, "Admin Console"),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Screen Body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (appState.dashboardIndex != 0) _buildWideAppBar(),
                  Expanded(
                    child: SafeArea(
                      child: _buildBody(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Default Mobile View
    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: Container(
        height: 65,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem(0, Icons.home_outlined, "Home"),
            _buildBottomNavItem(1, Icons.verified_user_outlined, "Verify"),
            _buildBottomNavItem(2, Icons.history, "History"),
            _buildBottomNavItem(3, Icons.bar_chart, "Insights"),
            _buildBottomNavItem(4, Icons.person_outline, "Profile"),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    // If it's Home screen, the header is embedded inside HomeScreen itself for better layout
    if (appState.dashboardIndex == 0) return null;

    String title = "";
    if (appState.dashboardIndex == 1) title = "Verification Deck";
    if (appState.dashboardIndex == 2) title = "Verification History";
    if (appState.dashboardIndex == 3) title = "Verification Insights";
    if (appState.dashboardIndex == 4) title = "Profile Settings";
    if (appState.dashboardIndex == 5) title = "Admin & n8n Panel";

    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          color: theme.brightness == Brightness.dark ? Colors.white : Colors.black87,
        ),
      ),
      centerTitle: true,
      shape: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
    );
  }

  Widget _buildWideAppBar() {
    final theme = Theme.of(context);
    String title = "";
    if (appState.dashboardIndex == 1) title = "Misinformation Verification Deck";
    if (appState.dashboardIndex == 2) title = "System Audit History Logs";
    if (appState.dashboardIndex == 3) title = "AI Verification Statistics & Insights";
    if (appState.dashboardIndex == 4) title = "User Profile Configurations";
    if (appState.dashboardIndex == 5) title = "Admin & n8n Automation Diagnostics";

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (appState.dashboardIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const VerifyScreen();
      case 2:
        return const HistoryScreen();
      case 3:
        return const InsightsScreen();
      case 4:
        return const ProfileScreen();
      case 5:
        return const AdminScreen();
      default:
        return const HomeScreen();
    }
  }

  Widget _buildSideNavItem(int index, IconData icon, String label) {
    final isSelected = appState.dashboardIndex == index;
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () {
          appState.setDashboardIndex(index);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? theme.colorScheme.primary : Colors.grey[500],
                size: 20,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.primary : Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon, String label) {
    final isSelected = appState.dashboardIndex == index;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        appState.setDashboardIndex(index);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? theme.colorScheme.primary.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isSelected ? theme.colorScheme.primary : Colors.grey[500],
              size: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? theme.colorScheme.primary : Colors.grey[500],
            ),
          )
        ],
      ),
    );
  }
}
