import 'package:flutter/material.dart';
import 'package:n8ntrial/models/app_state.dart';

class TruthLensAuthScreen extends StatefulWidget {
  const TruthLensAuthScreen({super.key});

  @override
  State<TruthLensAuthScreen> createState() => _TruthLensAuthScreenState();
}

class _TruthLensAuthScreenState extends State<TruthLensAuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _forgotFormKey = GlobalKey<FormState>();

  // Login Controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  // Register Controllers
  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();

  // Forgot Password Controller
  final _forgotEmailController = TextEditingController();

  bool _isLoginPasswordObscured = true;
  bool _isRegisterPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;

  // Track Forgot Password Mode
  bool _isForgotPasswordMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Direct Login Bypassing Credentials
    appState.login();

    setState(() {
      _isLoading = false;
    });

    _showNotification("Access Granted. Initializing TruthLens Engine...");
  }

  void _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final success = appState.registerUser(
      _registerNameController.text.trim(),
      _registerEmailController.text.trim(),
      _registerPasswordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      _showNotification("Credentials registered. Please sign in.");
      _registerFormKey.currentState!.reset();
      _loginEmailController.text = _registerEmailController.text;
      _registerNameController.clear();
      _registerEmailController.clear();
      _registerPasswordController.clear();
      _registerConfirmPasswordController.clear();
      _tabController.animateTo(0);
    } else {
      _showNotification("Registration failed. Email is already registered.", isError: true);
    }
  }

  void _handleForgotPassword() async {
    if (!_forgotFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isForgotPasswordMode = false;
    });

    _showNotification("Password reset security tokens dispatched to email.");
  }

  void _triggerBiometricLogin() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future.delayed(const Duration(seconds: 2), () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
                appState.login();
                _showNotification("Biometrics Verified. Access Granted.");
              }
            });

            return AlertDialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  // Glowing biometric scanner
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      border: Border.all(color: theme.colorScheme.primary, width: 2),
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      size: 40,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Touch ID / Face ID",
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Place your finger on sensor or look at camera to scan credentials...",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(
                    width: 80,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _triggerGoogleLogin() async {
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    appState.login();
    _showNotification("Authenticated via Google Cloud IAM Portal.");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480.0),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Branding Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          size: 38,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "TruthLens AI",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          fontFamily: 'monospace',
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "AUTOMATED DEEPFORENSIC ENGINE",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.secondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Main Form Switcher
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: _isForgotPasswordMode 
                      ? _buildForgotPasswordForm(theme, isDark)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tabs
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicatorColor: theme.colorScheme.primary,
                                indicatorWeight: 2,
                                labelColor: isDark ? Colors.white : Colors.black87,
                                unselectedLabelColor: Colors.grey[500],
                                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace'),
                                tabs: const [
                                  Tab(text: "SIGN IN"),
                                  Tab(text: "CREATE KEY"),
                                ],
                              ),
                            ),

                            // Forms view
                            SizedBox(
                              height: _tabController.index == 0 ? 320 : 420,
                              child: TabBarView(
                                controller: _tabController,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  _buildLoginForm(theme, isDark),
                                  _buildRegisterForm(theme, isDark),
                                ],
                              ),
                            ),
                          ],
                        ),
                  ),
                ),
                const SizedBox(height: 24),

                // Social / Biometric Login Block (only on Sign In mode)
                if (!_isForgotPasswordMode && _tabController.index == 0 && !_isLoading) ...[
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "SECURE PORTALS",
                          style: TextStyle(fontSize: 9, fontFamily: 'monospace', color: Colors.grey[500]),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Google Login
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _triggerGoogleLogin,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: theme.dividerColor),
                          ),
                          icon: const Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
                          label: const Text(
                            "Google Sign-In",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Biometric Login
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _triggerBiometricLogin,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: theme.dividerColor),
                          ),
                          icon: Icon(Icons.fingerprint, size: 18, color: theme.colorScheme.primary),
                          label: const Text(
                            "Biometrics",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildLoginForm(ThemeData theme, bool isDark) {
    return Form(
      key: _loginFormKey,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email Field
            _buildTextFormField(
              controller: _loginEmailController,
              label: "EMAIL ADDRESS",
              hint: "agent@truthlens.ai",
              icon: Icons.alternate_email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return "Email is required";
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                  return "Enter a valid email address";
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Password Field
            _buildTextFormField(
              controller: _loginPasswordController,
              label: "DECRYPT KEY",
              hint: "Security pin password",
              icon: Icons.vpn_key_outlined,
              obscureText: _isLoginPasswordObscured,
              suffixIcon: IconButton(
                icon: Icon(
                  _isLoginPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isLoginPasswordObscured = !_isLoginPasswordObscured;
                  });
                },
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return "Password is required";
                return null;
              },
            ),
            
            // Forgot Password Trigger
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _isForgotPasswordMode = true;
                  });
                },
                child: Text(
                  "Recover Key?",
                  style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Action Button
            _buildSubmitButton(
              onPressed: _handleLogin,
              text: "LAUNCH DASHBOARD",
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterForm(ThemeData theme, bool isDark) {
    return Form(
      key: _registerFormKey,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Full Name Field
              _buildTextFormField(
                controller: _registerNameController,
                label: "OFFICER NAME",
                hint: "Jane Doe",
                icon: Icons.person_outline,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Name is required";
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Email Field
              _buildTextFormField(
                controller: _registerEmailController,
                label: "EMAIL ADDRESS",
                hint: "agent@truthlens.ai",
                icon: Icons.alternate_email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Email is required";
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                    return "Enter a valid email address";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Password Field
              _buildTextFormField(
                controller: _registerPasswordController,
                label: "ENCRYPTION PASSWORD",
                hint: "Min 6 chars",
                icon: Icons.lock_open_outlined,
                obscureText: _isRegisterPasswordObscured,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isRegisterPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isRegisterPasswordObscured = !_isRegisterPasswordObscured;
                    });
                  },
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Password is required";
                  if (v.length < 6) return "Password must be at least 6 characters";
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Confirm Password Field
              _buildTextFormField(
                controller: _registerConfirmPasswordController,
                label: "CONFIRM DECRYPT KEY",
                hint: "Verify security code",
                icon: Icons.lock_outline,
                obscureText: _isConfirmPasswordObscured,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                    });
                  },
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Please confirm password";
                  if (v != _registerPasswordController.text) return "Passwords do not match";
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Action Button
              _buildSubmitButton(
                onPressed: _handleRegister,
                text: "REGISTER CREDENTIALS",
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordForm(ThemeData theme, bool isDark) {
    return Form(
      key: _forgotFormKey,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isForgotPasswordMode = false;
                    });
                  },
                  icon: const Icon(Icons.arrow_back, size: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  "Recover Password",
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "Enter your registered security email below. We will transmit instructions to decrypt your credential key.",
              style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 20),
            _buildTextFormField(
              controller: _forgotEmailController,
              label: "RECOVERY EMAIL ADDRESS",
              hint: "agent@truthlens.ai",
              icon: Icons.alternate_email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return "Email is required";
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                  return "Enter a valid email address";
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            _buildSubmitButton(
              onPressed: _handleForgotPassword,
              text: "DISPATCH RESET TOKEN",
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.grey[700] : Colors.grey[400], fontSize: 12),
            prefixIcon: Icon(icon, size: 16, color: theme.colorScheme.primary.withOpacity(0.7)),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark ? const Color(0xFF0C1220) : const Color(0xFFF1F3F9),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.dividerColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.colorScheme.error, width: 1.2),
            ),
            errorStyle: const TextStyle(fontSize: 8, height: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton({
    required VoidCallback onPressed,
    required String text,
    required ThemeData theme,
  }) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.5),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
    );
  }
}
