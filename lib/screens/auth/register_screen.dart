/// Registration screen for new SmartShutter users.
/// Image covers exact 50% top, form covers exact 50% bottom.
/// All content scales proportionally with screen height.
/// Integrates with the hosted backend API for account creation.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/services/auth_service.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/auth/login_screen.dart';
import 'package:smart_shutter/screens/onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
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

      // Fetch profile
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
      // Registration succeeded but auto-login failed; go to login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Please log in.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
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
      body: SizedBox(
        height: screenHeight,
        child: Column(
          children: [
            // ──── TOP: Image ────
            Expanded(
              child: Image.asset(
                'assets/images/register_login/register_top.png',
                width: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),

            // ──── BOTTOM: Form ────
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final formHeight = constraints.maxHeight;
                  final s = (formHeight / 480).clamp(0.0, 1.0);

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
                          child: Icon(Icons.person_add_outlined, color: Colors.white, size: 20 * s),
                        ),
                      ),
                    ),
                    // Form content
                    Padding(
                      padding: EdgeInsets.fromLTRB(20 * s, 26 * s, 20 * s, 8 * s),
                      child: _buildForm(isDark, s),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
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
            'Create your account',
            style: TextStyle(
              fontSize: 20 * s,
              fontWeight: FontWeight.bold,
              color: AppTheme.ink(isDark),
              fontFamily: 'Outfit',
            ),
          ),
          SizedBox(height: 2 * s),
          Text(
            'Start capturing perfect photos, hands-free.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12 * s,
              color: AppTheme.muted(isDark),
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 12 * s),

          // Name row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52 * s,
                  child: TextFormField(
                    controller: _firstNameController,
                    style: TextStyle(color: AppTheme.ink(isDark), fontSize: 15 * s),
                    decoration: _inputDecoration(isDark, s, 'First Name', Icons.person_outline),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ),
              SizedBox(width: 8 * s),
              Expanded(
                child: SizedBox(
                  height: 52 * s,
                  child: TextFormField(
                    controller: _lastNameController,
                    style: TextStyle(color: AppTheme.ink(isDark), fontSize: 15 * s),
                    decoration: _inputDecoration(isDark, s, 'Last Name', Icons.person_outline),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * s),

          // Email
          SizedBox(
            height: 52 * s,
            child: TextFormField(
              controller: _emailController,
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
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (v.length < 8) return 'Minimum 8 characters';
                return null;
              },
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleRegister(),
              onChanged: (_) => setState(() {}),
            ),
          ),

          SizedBox(height: 24 * s),

          // Register button
          SizedBox(
            width: double.infinity,
            height: 50 * s,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
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
                      'Sign Up',
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

          // Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(color: AppTheme.muted(isDark), fontSize: 14 * s),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: Text(
                  'Log in',
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

  Widget _buildPasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) return const SizedBox.shrink();

    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#\$%\^\&\*]').hasMatch(password)) strength++;

    final colors = [AppTheme.danger, AppTheme.danger, AppTheme.warn, AppTheme.ok, AppTheme.ok];
    final labels = ['Very Weak', 'Weak', 'Fair', 'Strong', 'Very Strong'];
    final idx = (strength - 1).clamp(0, 4);

    return Column(
      children: [
        Row(
          children: List.generate(5, (i) {
            return Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i <= idx
                      ? colors[idx]
                      : (context.read<AppState>().isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.08)),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            labels[idx],
            style: TextStyle(fontSize: 11, color: colors[idx], fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
