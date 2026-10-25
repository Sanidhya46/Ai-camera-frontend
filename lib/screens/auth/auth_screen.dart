/// Unified Auth Screen supporting both Registration and Login with a sliding bottom sheet overlay.
/// The background displays the splash screen image with a slight dark/opaque overlay and branding.
/// Accurately matches Image 2 design mockup.
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/services/auth_service.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/onboarding_screen.dart';
import 'package:smart_shutter/screens/permissions_screen.dart';
import 'package:smart_shutter/screens/main_layout.dart';

enum AuthInitialMode { register, login }

class AuthScreen extends StatefulWidget {
  final AuthInitialMode initialMode;
  final bool animateEntrance;

  const AuthScreen({
    super.key,
    this.initialMode = AuthInitialMode.login,
    this.animateEntrance = true,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late bool _isRegisterMode;
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _sheetAnimController;
  late Animation<Offset> _sheetSlideAnimation;
  late Animation<double> _scrimFadeAnimation;

  @override
  void initState() {
    super.initState();
    _isRegisterMode = widget.initialMode == AuthInitialMode.register;

    _sheetAnimController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _sheetSlideAnimation = Tween<Offset>(
      begin: widget.animateEntrance ? const Offset(0, 1.0) : Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _sheetAnimController,
      curve: Curves.easeOutCubic,
    ));

    _scrimFadeAnimation = Tween<double>(
      begin: widget.animateEntrance ? 0.0 : 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sheetAnimController,
      curve: Curves.easeOut,
    ));

    if (widget.animateEntrance) {
      _sheetAnimController.forward();
    } else {
      _sheetAnimController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _sheetAnimController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );

    if (!mounted) return;

    if (result['error'] != null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] as String),
          backgroundColor: AppTheme.danger,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Registration succeeded, now auto-login
    final loginResult = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (loginResult['success'] == true) {
      final appState = context.read<AppState>();
      await appState.setAuthTokens(
        accessToken: loginResult['accessToken'] as String,
        refreshToken: loginResult['refreshToken'] as String,
      );

      final profileResult = await _authService.getProfile(
        loginResult['accessToken'] as String,
      );
      if (profileResult['success'] == true && mounted) {
        await appState.setCurrentUser(profileResult['data'] as Map<String, dynamic>);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _isRegisterMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created! Please log in.')),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (result['error'] != null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] as String),
          backgroundColor: AppTheme.danger,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final appState = context.read<AppState>();
    await appState.setAuthTokens(
      accessToken: result['accessToken'] as String,
      refreshToken: result['refreshToken'] as String,
    );

    final profileResult = await _authService.getProfile(
      result['accessToken'] as String,
    );
    if (profileResult['success'] == true && mounted) {
      await appState.setCurrentUser(profileResult['data'] as Map<String, dynamic>);
    }

    if (!mounted) return;
    appState.setTabIndex(0);

    bool hasPermissions = true;
    try {
      final cameraStatus = await Permission.camera.status;
      if (!kIsWeb) {
        final storageStatus = await Permission.storage.status;
        hasPermissions = cameraStatus.isGranted && storageStatus.isGranted;
      } else {
        hasPermissions = cameraStatus.isGranted;
      }
    } catch (_) {}

    if (!mounted) return;

    if (!appState.hasSeenOnboarding) {
      await appState.setOnboardingSeen(true);
    }

    if (!mounted) return;

    if (!appState.hasSeenPermissionsFlow || !hasPermissions) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PermissionsScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ──── 1. SPLASH SCREEN BACKGROUND IMAGE ────
          Image.asset(
            'assets/images/splash_screen/splash_screen_image.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.topCenter,
          ),

          // ──── 2. OPACITY / SCRIM OVERLAY ────
          AnimatedBuilder(
            animation: _scrimFadeAnimation,
            builder: (context, child) {
              return Container(
                color: Colors.black.withValues(
                  alpha: 0.38 * _scrimFadeAnimation.value,
                ),
              );
            },
          ),

          // ──── 3. BOTTOM OVERLAY SHEET (DIV) - NO UNWANTED DEAD SPACE, SITS AT BOTTOM ────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: _sheetSlideAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 30,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // Floating Badge centered on the top edge
                    Positioned(
                      top: -20,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 19,
                          backgroundColor: const Color(0xFF4F46E5),
                          child: Icon(
                            _isRegisterMode
                                ? Icons.person_add_alt_1_outlined
                                : Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                    ),

                    // Form Content - naturally wraps content without bottom dead space
                    SafeArea(
                      top: false,
                      child: SingleChildScrollView(
                        physics: isKeyboardOpen
                            ? const BouncingScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          20,
                          20,
                          20,
                          isKeyboardOpen ? keyboardHeight + 12 : 16,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title
                              Text(
                                _isRegisterMode ? 'Create your account' : 'Welcome back',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontFamily: 'Outfit',
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Subtitle
                              Text(
                                _isRegisterMode
                                    ? 'Start capturing perfect photos, hands-free.'
                                    : 'Log in to your account to continue.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // REGISTER FORM: First Name & Last Name
                              if (_isRegisterMode) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _firstNameController,
                                        hintText: 'First Name',
                                        icon: Icons.person_outline_rounded,
                                        isDark: isDark,
                                        validator: (v) =>
                                            v == null || v.trim().isEmpty ? 'Required' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _lastNameController,
                                        hintText: 'Last Name',
                                        icon: Icons.person_outline_rounded,
                                        isDark: isDark,
                                        validator: (v) =>
                                            v == null || v.trim().isEmpty ? 'Required' : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 9),
                              ],

                              // EMAIL FIELD
                              _buildTextField(
                                controller: _emailController,
                                hintText: 'Email',
                                icon: Icons.mail_outline_rounded,
                                isDark: isDark,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Email required';
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 9),

                              // PASSWORD FIELD
                              _buildTextField(
                                controller: _passwordController,
                                hintText: 'Password',
                                icon: Icons.lock_outline_rounded,
                                isDark: isDark,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF94A3B8),
                                    size: 19,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Password required';
                                  if (v.length < 8) return 'Minimum 8 characters';
                                  return null;
                                },
                              ),

                              // Forgot password link in Login mode
                              if (!_isRegisterMode) ...[
                                const SizedBox(height: 5),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Password reset link will be sent to your email.'),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 12),

                              // PRIMARY SUBMIT BUTTON
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : (_isRegisterMode ? _handleRegister : _handleLogin),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4F46E5),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          _isRegisterMode ? 'Sign Up' : 'Log In',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // SWITCH MODE FOOTER (Underneath form)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isRegisterMode
                                        ? 'Already have an account? '
                                        : "Don't have an account? ",
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isRegisterMode = !_isRegisterMode;
                                        _formKey.currentState?.reset();
                                      });
                                    },
                                    child: Text(
                                      _isRegisterMode ? 'Log in' : 'Sign up',
                                      style: const TextStyle(
                                        color: Color(0xFF4F46E5),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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


  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isDark,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9.5),
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          fontSize: 13.5,
        ),
        prefixIcon: Icon(
          icon,
          size: 19,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.6)
            : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF4F46E5),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFEF4444),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}


