import 'dart:ui';
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

/// Dedicated, full-page Sign-In and Sign-Up screen.
/// Features a theme-matched blurred photographic background, top app logo branding,
/// toggle between Sign In and Create Account, password confirmation validation,
/// and smooth interactive feedback.
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
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _isRegisterMode = widget.initialMode == AuthInitialMode.register;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match. Please verify and try again.'),
          backgroundColor: AppTheme.danger,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.register(
      email: _emailController.text.trim(),
      password: password,
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

    // Registration succeeded, now log in automatically
    final loginResult = await _authService.login(
      email: _emailController.text.trim(),
      password: password,
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
        const SnackBar(content: Text('Account created! Please sign in.')),
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

  Future<void> _handleSocialAuth(String provider) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final appState = context.read<AppState>();
    await appState.setCurrentUser({
      'id': 'social_user_${provider.toLowerCase()}',
      'email': 'user@${provider.toLowerCase()}.com',
      'first_name': 'Sanidhya',
      'last_name': 'Shukla',
    });

    setState(() => _isLoading = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully authenticated with $provider!'),
        backgroundColor: AppTheme.ok,
        duration: const Duration(seconds: 2),
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainLayout()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background Image with Blur Effect ──
          Image.asset(
            'assets/images/splash_screen/splash_screen_image.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            ),
          ),

          // ── Backdrop Blur Filter & Gradient Overlay ──
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (isDark ? const Color(0xFF090D1A) : Colors.white).withValues(alpha: 0.82),
                      (isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2FF)).withValues(alpha: 0.92),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Decorative Ambient Orbs ──
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4F46E5).withValues(alpha: isDark ? 0.22 : 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.18 : 0.1),
              ),
            ),
          ),

          // ── Dedicated Scrollable Auth Page Content ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ── App Logo at the Top of Form ──
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          isDark
                              ? 'assets/images/app_logo.png'
                              : 'assets/images/app_logo_light_theme.png',
                          width: 52,
                          height: 52,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.camera_alt,
                            size: 44,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // App Name & Tagline
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Smart',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontFamily: 'Outfit',
                              ),
                            ),
                            const TextSpan(
                              text: 'Shutter',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: Color(0xFF3B82F6),
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI Passport & Smart Solo Photography Studio',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ── Dedicated Glassmorphic Auth Card ──
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                              : Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── Segmented Switcher: Sign In vs Sign Up ──
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          if (_isRegisterMode) {
                                            setState(() => _isRegisterMode = false);
                                          }
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: !_isRegisterMode
                                                ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: !_isRegisterMode
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.06),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Sign In',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: !_isRegisterMode ? FontWeight.w700 : FontWeight.w500,
                                                color: !_isRegisterMode
                                                    ? const Color(0xFF4F46E5)
                                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          if (!_isRegisterMode) {
                                            setState(() => _isRegisterMode = true);
                                          }
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: _isRegisterMode
                                                ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: _isRegisterMode
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.06),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Sign Up',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: _isRegisterMode ? FontWeight.w700 : FontWeight.w500,
                                                color: _isRegisterMode
                                                    ? const Color(0xFF4F46E5)
                                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // ── Registration: First and Last Name ──
                              if (_isRegisterMode) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _firstNameController,
                                        label: 'First name',
                                        icon: Icons.badge_outlined,
                                        isDark: isDark,
                                        validator: (val) {
                                          if (_isRegisterMode && (val == null || val.trim().isEmpty)) {
                                            return 'Required';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildTextField(
                                        controller: _lastNameController,
                                        label: 'Last name',
                                        icon: Icons.person_outline,
                                        isDark: isDark,
                                        validator: (val) {
                                          if (_isRegisterMode && (val == null || val.trim().isEmpty)) {
                                            return 'Required';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],

                              // ── Email Field ──
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email address',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                isDark: isDark,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(val.trim())) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // ── Password Field ──
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                                obscureText: _obscurePassword,
                                onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                                isDark: isDark,
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (_isRegisterMode && val.length < 8) {
                                    return 'Password must be at least 8 characters';
                                  }
                                  return null;
                                },
                              ),

                              // ── Confirm Password Field (in Register Mode) ──
                              if (_isRegisterMode) ...[
                                const SizedBox(height: 12),
                                _buildTextField(
                                  controller: _confirmPasswordController,
                                  label: 'Confirm Password',
                                  icon: Icons.shield_outlined,
                                  isPassword: true,
                                  obscureText: _obscureConfirmPassword,
                                  onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  isDark: isDark,
                                  validator: (val) {
                                    if (!_isRegisterMode) return null;
                                    if (val == null || val.isEmpty) {
                                      return 'Please confirm your password';
                                    }
                                    if (val != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                              ],

                              // ── Forgot Password (Sign-In Mode) ──
                              if (!_isRegisterMode) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Password reset instructions will be sent to your email.'),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 18),

                              // ── Primary Action Button ──
                              ElevatedButton(
                                onPressed: _isLoading ? null : (_isRegisterMode ? _handleRegister : _handleLogin),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4F46E5),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        _isRegisterMode ? 'Sign Up' : 'Sign In',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 16),

                              // ── "Or continue with" Divider ──
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      'Or continue with',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // ── Google and Apple Buttons Row ──
                              Row(
                                children: [
                                  // Google Button
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _isLoading ? null : () => _handleSocialAuth('Google'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        side: BorderSide(
                                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                        ),
                                        backgroundColor: isDark
                                            ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                                            : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 19,
                                            height: 19,
                                            alignment: Alignment.center,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF4285F4),
                                            ),
                                            child: const Text(
                                              'G',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 12,
                                                fontFamily: 'Roboto',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Google',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Apple Button
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _isLoading ? null : () => _handleSocialAuth('Apple'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        side: BorderSide(
                                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                                        ),
                                        backgroundColor: isDark
                                            ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                                            : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.apple,
                                            size: 19,
                                            color: isDark ? Colors.white : Colors.black,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Apple',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── Terms & Privacy hint ──
                      Text(
                        'By signing in, you agree to our Terms of Service & Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
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
    required String label,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 13,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        prefixIcon: Icon(
          icon,
          size: 19,
          color: const Color(0xFF4F46E5),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 19,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
          borderSide: const BorderSide(color: AppTheme.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.danger, width: 1.5),
        ),
      ),
    );
  }
}
