/// Login screen for existing SmartShutter users.
/// Image covers exact 50% top, form covers exact 50% bottom.
/// All content scales proportionally with screen height.
/// Integrates with hosted backend API for authentication.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/services/auth_service.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/auth/register_screen.dart';
import 'package:smart_shutter/screens/onboarding_screen.dart';
import 'package:smart_shutter/screens/main_layout.dart';
import 'package:smart_shutter/screens/permissions_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (result['error'] != null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] as String),
          backgroundColor: AppTheme.danger,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final appState = context.read<AppState>();
    await appState.setAuthTokens(
      accessToken: result['accessToken'] as String,
      refreshToken: result['refreshToken'] as String,
    );

    // Fetch profile
    final profileResult = await _authService.getProfile(
      result['accessToken'] as String,
    );
    if (profileResult['success'] == true && mounted) {
      await appState.setCurrentUser(profileResult['data'] as Map<String, dynamic>);
    }

    if (!mounted) return;

    // Ensure home page is visible after login
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
    } catch (_) {
      // Ignore if permission check fails
    }

    if (!mounted) return;

    // Navigate based on onboarding status and permissions
    // Bypassing onboarding for logged-in users as requested
    if (!appState.hasSeenOnboarding) {
      await appState.setOnboardingSeen(true);
    }
    
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
    final screenHeight = MediaQuery.of(context).size.height;
    final halfHeight = screenHeight * 0.5;

    // Scale factor: adjusted to 450 to prevent vertical overflow on smaller screens
    // Scale factor will be calculated dynamically based on remaining space

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? const Color(0xFF010209) : const Color(0xFFF4F6F9),
      body: Stack(
        children: [
          // ──── TOP: Image ────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: halfHeight,
            child: Image.asset(
              'assets/images/register_login/login_top.png',
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // ──── BOTTOM: Form ────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            top: halfHeight - MediaQuery.of(context).viewInsets.bottom,
            left: 0,
            right: 0,
            height: halfHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final formHeight = constraints.maxHeight;
                final s = (formHeight / 450).clamp(0.0, 1.0);

                return Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                        border: isDark ? Border(
                          top: BorderSide(color: Colors.white.withOpacity(0.08)),
                          left: BorderSide(color: Colors.white.withOpacity(0.08)),
                          right: BorderSide(color: Colors.white.withOpacity(0.08)),
                        ) : Border(
                          top: BorderSide(color: AppTheme.lightLine.withOpacity(0.5)),
                          left: BorderSide(color: AppTheme.lightLine.withOpacity(0.5)),
                          right: BorderSide(color: AppTheme.lightLine.withOpacity(0.5)),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5),
                            blurRadius: isDark ? 25 : 30,
                            spreadRadius: isDark ? 5 : 10,
                            offset: const Offset(0, -8),
                          ),
                        ],
                      ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // Circular icon floating on the edge
                    Positioned(
                      top: -24 * s,
                      child: Container(
                        padding: EdgeInsets.all(6 * s),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 20 * s,
                          backgroundColor: AppTheme.brand,
                          child: Icon(Icons.lock_outline, color: Colors.white, size: 20 * s),
                        ),
                      ),
                    ),
                    // Form content
                    Positioned.fill(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20 * s, 26 * s, 20 * s, 8 * s),
                          child: _buildForm(isDark, s),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isDark, double s) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 20 * s,
              fontWeight: FontWeight.bold,
              color: AppTheme.ink(isDark),
              fontFamily: 'Outfit',
            ),
          ),
          SizedBox(height: 2 * s),
          Text(
            'Sign in to continue capturing moments.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12 * s,
              color: AppTheme.muted(isDark),
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 12 * s),

          // Email
          SizedBox(
            height: 52 * s,
            child: TextFormField(
              controller: _emailController,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(color: AppTheme.ink(isDark), fontSize: 15 * s),
              decoration: _inputDecoration(isDark, s, 'Email', Icons.email_outlined),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email required';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
          ),
          SizedBox(height: 14 * s),

          // Password
          SizedBox(
            height: 52 * s,
            child: TextFormField(
            controller: _passwordController,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(color: AppTheme.ink(isDark), fontSize: 15 * s),
              obscureText: _obscurePassword,
              decoration: _inputDecoration(isDark, s, 'Password', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppTheme.muted(isDark),
                    size: 20 * s,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Password required' : null,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
            ),
          ),

          SizedBox(height: 6 * s),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Forgot password coming soon!')),
                );
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: AppTheme.brand,
                  fontSize: 13 * s,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          SizedBox(height: 24 * s),

          // Login button
          SizedBox(
            width: double.infinity,
            height: 50 * s,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brand,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14 * s),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 20 * s,
                      height: 20 * s,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Log In',
                      style: TextStyle(
                        fontSize: 16 * s,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 12 * s),

          // Or continue with
          Row(
            children: [
              Expanded(child: Divider(color: AppTheme.muted(isDark).withOpacity(0.2))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10 * s),
                child: Text(
                  'or continue with',
                  style: TextStyle(color: AppTheme.muted(isDark), fontSize: 11 * s),
                ),
              ),
              Expanded(child: Divider(color: AppTheme.muted(isDark).withOpacity(0.2))),
            ],
          ),
          SizedBox(height: 12 * s),

          // Social Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44 * s,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.g_mobiledata, color: Colors.blue, size: 24 * s),
                    label: Text('Google', style: TextStyle(color: AppTheme.ink(isDark), fontSize: 14 * s)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12 * s)),
                      side: BorderSide(color: AppTheme.muted(isDark).withOpacity(0.2)),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10 * s),
              Expanded(
                child: SizedBox(
                  height: 44 * s,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.apple, color: isDark ? Colors.white : Colors.black, size: 22 * s),
                    label: Text('Apple', style: TextStyle(color: AppTheme.ink(isDark), fontSize: 14 * s)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12 * s)),
                      side: BorderSide(color: AppTheme.muted(isDark).withOpacity(0.2)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * s),

          // Register link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(color: AppTheme.muted(isDark), fontSize: 14 * s),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: Text(
                  'Sign up',
                  style: TextStyle(
                    color: AppTheme.brand,
                    fontSize: 14 * s,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(bool isDark, double s, String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.muted(isDark), fontSize: 15 * s),
      prefixIcon: Icon(icon, color: AppTheme.muted(isDark), size: 20 * s),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12 * s),
        borderSide: BorderSide(color: AppTheme.muted(isDark).withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12 * s),
        borderSide: BorderSide(color: AppTheme.muted(isDark).withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12 * s),
        borderSide: const BorderSide(color: AppTheme.brand),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: 10 * s, horizontal: 10 * s),
      errorStyle: const TextStyle(height: 0, fontSize: 0, color: Colors.transparent),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12 * s),
        borderSide: const BorderSide(color: AppTheme.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12 * s),
        borderSide: const BorderSide(color: AppTheme.danger, width: 2.0),
      ),
    );
  }
}
