import 'package:flutter/material.dart';
import 'package:n8ntrial/models/models.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // Navigation indexes
  int dashboardIndex = 0; // 0: Home, 1: Verify, 2: History, 3: Insights, 4: Profile
  TabController? verifyTabController; // News, Images, Backtrack inside Verify screen
  int initialVerifyTabIndex = 0;

  // Authentication simulator
  bool isLoggedIn = false;
  Map<String, String>? currentUser;

  final List<Map<String, String>> _registeredUsers = [
    {
      'name': 'Sejal Rai',
      'email': 'sejal.rai@example.com',
      'password': 'password123',
    }
  ];

  // Theme configuration simulator
  bool isDarkMode = true;

  // Insights filter simulator
  String timePeriod = "This Week";

  // Active items for verification
  NewsPreset? activeNewsPreset;
  ImagePreset? activeImagePreset;
  
  // Custom callbacks
  void Function(NewsPreset)? onTriggerNewsAnalysis;
  void Function(ImagePreset)? onTriggerImageAnalysis;

  // Active Backtrack report data
  BacktrackReport? activeBacktrackReport;
  String currentBacktrackTitle = "";
  VoidCallback? onStartBacktrackSearch;

  // Set active tab on dashboard
  void setDashboardIndex(int index) {
    dashboardIndex = index;
    notifyListeners();
  }

  // Toggle Dark Mode
  void toggleDarkMode(bool value) {
    isDarkMode = value;
    notifyListeners();
  }

  // Set Time Period Filter
  void setTimePeriod(String value) {
    timePeriod = value;
    notifyListeners();
  }

  // Login/Logout flows
  void login() {
    isLoggedIn = true;
    currentUser ??= _registeredUsers[0];
    dashboardIndex = 0;
    notifyListeners();
  }

  bool registerUser(String name, String email, String password) {
    if (_registeredUsers.any((u) => u['email']?.toLowerCase() == email.toLowerCase())) {
      return false;
    }
    _registeredUsers.add({
      'name': name,
      'email': email,
      'password': password,
    });
    return true;
  }

  bool loginUser(String email, String password) {
    final user = _registeredUsers.firstWhere(
      (u) => u['email']?.toLowerCase() == email.toLowerCase() && u['password'] == password,
      orElse: () => {},
    );
    if (user.isNotEmpty) {
      currentUser = user;
      isLoggedIn = true;
      dashboardIndex = 0;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    isLoggedIn = false;
    currentUser = null;
    notifyListeners();
  }

  // Backtrack request flow
  void requestBacktrack(String title, BacktrackReport report) {
    activeBacktrackReport = report;
    currentBacktrackTitle = title;
    notifyListeners();

    if (onStartBacktrackSearch != null) {
      onStartBacktrackSearch!();
    }
  }

  // Helper triggers for verification from home screen quick buttons
  void startVerifyNews(NewsPreset preset) {
    initialVerifyTabIndex = 0;
    setDashboardIndex(1);
    if (verifyTabController != null) {
      verifyTabController!.animateTo(0); // News tab
    }
    if (onTriggerNewsAnalysis != null) {
      onTriggerNewsAnalysis!(preset);
    }
  }

  void startVerifyImage(ImagePreset preset) {
    initialVerifyTabIndex = 1;
    setDashboardIndex(1);
    if (verifyTabController != null) {
      verifyTabController!.animateTo(1); // Image tab
    }
    if (onTriggerImageAnalysis != null) {
      onTriggerImageAnalysis!(preset);
    }
  }

  void startVerifyUrl(String url) {
    initialVerifyTabIndex = 2;
    setDashboardIndex(1);
    if (verifyTabController != null) {
      verifyTabController!.animateTo(2); // URL tab
    }
  }

  void startVerifyVideo() {
    initialVerifyTabIndex = 3;
    setDashboardIndex(1);
    if (verifyTabController != null) {
      verifyTabController!.animateTo(3); // Video tab
    }
  }

  bool hasSeenOnboarding = false;

  void completeOnboarding() {
    hasSeenOnboarding = true;
    notifyListeners();
  }
}

final appState = AppState();
