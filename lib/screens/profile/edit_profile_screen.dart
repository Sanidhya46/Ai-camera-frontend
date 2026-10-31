library;

import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';

/// Full-screen Edit Profile page matching the target UI design.
/// Features:
/// - Circle back button and top-right "Save Changes" pill button
/// - Glowing avatar halo with camera badge and "Change Photo" pill button
/// - Grouped cards: "Personal Information", "Account Details", "Location & Status"
/// - Well-distributed typography with no browser autofill bubbles
/// - Custom Status editing support
/// - Inline in-place OTP verification for Email and Phone number
/// - Beautiful purple themed Calendar picker
/// - Full-width bottom "Save Changes" gradient button
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;
  late final TextEditingController _dobController;
  late final TextEditingController _customStatusController;

  late final TextEditingController _emailOtpController;
  late final TextEditingController _mobileOtpController;

  late String _selectedGender;
  late String _selectedProfession;
  late String _selectedPronouns;
  late String _selectedCountry;
  late String _selectedStatus;

  late bool _isMobileVerified;
  late bool _isEmailVerified;

  bool _showEmailOtpField = false;
  bool _showMobileOtpField = false;
  bool _isCustomStatus = false;

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-Binary',
    'Prefer not to say',
  ];
  final List<String> _professionOptions = [
    'Software Developer',
    'Visual Artist',
    'Photographer',
    'Content Creator',
    'Designer',
    'Student',
    'Entrepreneur',
    'Other',
  ];
  final List<String> _pronounsOptions = [
    'He/Him',
    'She/Her',
    'They/Them',
    'Prefer not to say',
  ];
  final List<String> _countryOptions = [
    'India',
    'United States',
    'United Kingdom',
    'Canada',
    'Australia',
    'Germany',
    'France',
    'Singapore',
    'Other',
  ];
  final List<String> _statusPresetOptions = [
    'Active',
    'Busy',
    'Away',
    'Offline',
    'Custom Status...',
  ];

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _firstNameController = TextEditingController(text: appState.userFirstName);
    _lastNameController = TextEditingController(text: appState.userLastName);
    _usernameController = TextEditingController(text: appState.userUsername);
    _emailController = TextEditingController(text: appState.userEmail);
    _mobileController = TextEditingController(text: appState.userMobile);
    _dobController = TextEditingController(text: appState.userDob);
    _customStatusController = TextEditingController();

    _emailOtpController = TextEditingController();
    _mobileOtpController = TextEditingController();

    _selectedGender = appState.userGender;
    _selectedProfession = appState.userProfession;
    _selectedPronouns = appState.userPronouns;
    _selectedCountry = appState.userCountry;

    final curStatus = appState.userStatus;
    if (['Active', 'Busy', 'Away', 'Offline'].contains(curStatus)) {
      _selectedStatus = curStatus;
      _isCustomStatus = false;
    } else {
      _selectedStatus = curStatus;
      _customStatusController.text = curStatus;
      _isCustomStatus = true;
    }

    _isMobileVerified = appState.isMobileVerified;
    _isEmailVerified = appState.isEmailVerified;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _customStatusController.dispose();
    _emailOtpController.dispose();
    _mobileOtpController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final appState = context.read<AppState>();
    final finalStatus =
        _isCustomStatus && _customStatusController.text.trim().isNotEmpty
        ? _customStatusController.text.trim()
        : _selectedStatus;

    await appState.updateExtendedProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      username: _usernameController.text.trim(),
      mobile: _mobileController.text.trim(),
      dob: _dobController.text.trim(),
      gender: _selectedGender,
      profession: _selectedProfession,
      pronouns: _selectedPronouns,
      country: _selectedCountry,
      status: finalStatus,
      isMobileVerified: _isMobileVerified,
      isEmailVerified: _isEmailVerified,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Profile updated successfully!'),
            ],
          ),
          backgroundColor: AppTheme.ok,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── Soft background ambient light spots ──
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF6366F1,
                ).withValues(alpha: isDark ? 0.15 : 0.08),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF8B5CF6,
                ).withValues(alpha: isDark ? 0.12 : 0.07),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top Bar (Back button, Title + Subtitle, Save Changes Pill) ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Circular Back Button
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.2 : 0.06,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 15,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title & Subtitle with FittedBox so it never wraps or breaks syllables
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  fontFamily: 'Outfit',
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Update your personal details',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Top-right "Save Changes" Pill Button with full, proud height
                      ElevatedButton.icon(
                        onPressed: _handleSave,
                        icon: const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          elevation: 3,
                          minimumSize: const Size(0, 42),
                          shadowColor: const Color(
                            0xFF6366F1,
                          ).withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable Form Area ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Avatar with Glowing Halo & Change Photo Button ──
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(
                                            0xFF6366F1,
                                          ).withValues(alpha: 0.35),
                                          const Color(
                                            0xFF8B5CF6,
                                          ).withValues(alpha: 0.15),
                                        ],
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: ClipOval(
                                      child: _buildAvatarImage(appState),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _pickPhoto(context, appState),
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark
                                              ? const Color(0xFF0F172A)
                                              : Colors.white,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF6366F1,
                                            ).withValues(alpha: 0.4),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // "Change Photo" pill button
                              InkWell(
                                onTap: () => _pickPhoto(context, appState),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF6366F1,
                                    ).withValues(alpha: isDark ? 0.18 : 0.10),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF6366F1,
                                      ).withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.photo_camera_rounded,
                                        size: 14,
                                        color: Color(0xFF6366F1),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'Change Photo',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // ══════════════════════════════════════════
                        // CARD 1: PERSONAL INFORMATION
                        // ══════════════════════════════════════════
                        _buildSectionCard(
                          isDark: isDark,
                          icon: Icons.person_rounded,
                          title: 'Personal Information',
                          showAccentLine: true,
                          children: [
                            // Row 1: First Name & Last Name (2 columns)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFormField(
                                    label: 'First Name',
                                    controller: _firstNameController,
                                    icon: Icons.person_rounded,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildFormField(
                                    label: 'Last Name',
                                    controller: _lastNameController,
                                    icon: Icons.person_rounded,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Row 2: Date of Birth & Gender (2 columns)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildClickableBox(
                                    label: 'Date of Birth',
                                    value: _dobController.text,
                                    icon: Icons.calendar_month_outlined,
                                    isDark: isDark,
                                    onTap: () => _pickCustomDate(context),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildDropdownSelector(
                                    label: 'Gender',
                                    value: _selectedGender,
                                    icon: Icons.male_rounded,
                                    items: _genderOptions,
                                    isDark: isDark,
                                    onChanged: (val) =>
                                        setState(() => _selectedGender = val),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Row 3: Profession & Pronouns (2 columns)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdownSelector(
                                    label: 'Profession',
                                    value: _selectedProfession,
                                    icon: Icons.business_center_outlined,
                                    items: _professionOptions,
                                    isDark: isDark,
                                    onChanged: (val) => setState(
                                      () => _selectedProfession = val,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildDropdownSelector(
                                    label: 'Pronouns',
                                    value: _selectedPronouns,
                                    icon: Icons.favorite_border_rounded,
                                    items: _pronounsOptions,
                                    isDark: isDark,
                                    onChanged: (val) =>
                                        setState(() => _selectedPronouns = val),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ══════════════════════════════════════════
                        // CARD 2: ACCOUNT DETAILS
                        // ══════════════════════════════════════════
                        _buildSectionCard(
                          isDark: isDark,
                          icon: Icons.credit_card_rounded,
                          title: 'Account Details',
                          showAccentLine: true,
                          children: [
                            // Username with Available badge
                            _buildFormField(
                              label: 'Username',
                              controller: _usernameController,
                              icon: Icons.alternate_email_rounded,
                              isDark: isDark,
                              trailingBadge: _buildStatusPill(
                                label: 'Available',
                                icon: Icons.check_circle_rounded,
                                color: const Color(0xFF10B981),
                                bgColor: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.12),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Email Address (with in-place OTP field toggle)
                            _buildFormField(
                              label: 'Email Address',
                              controller: _emailController,
                              icon: Icons.mail_rounded,
                              isDark: isDark,
                              readOnly: true,
                              trailingBadge: _isEmailVerified
                                  ? _buildStatusPill(
                                      label: 'Verified',
                                      icon: Icons.check_circle_rounded,
                                      color: const Color(0xFF10B981),
                                      bgColor: const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.12),
                                    )
                                  : _buildVerifyActionPill(
                                      label: _showEmailOtpField
                                          ? 'Close'
                                          : 'Verify',
                                      onTap: () {
                                        setState(() {
                                          _showEmailOtpField =
                                              !_showEmailOtpField;
                                        });
                                      },
                                    ),
                            ),
                            // In-place OTP field for Email
                            if (_showEmailOtpField && !_isEmailVerified) ...[
                              const SizedBox(height: 8),
                              _buildInlineOtpSection(
                                isDark: isDark,
                                targetTitle: 'Email',
                                targetValue: _emailController.text,
                                controller: _emailOtpController,
                                onConfirm: () {
                                  if (_emailOtpController.text.trim().length >=
                                      4) {
                                    setState(() {
                                      _isEmailVerified = true;
                                      _showEmailOtpField = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Email address verified successfully!',
                                        ),
                                        backgroundColor: AppTheme.ok,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter 4-digit code (e.g. 1234)',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                            const SizedBox(height: 12),

                            // Mobile Number (with in-place OTP field toggle)
                            _buildFormField(
                              label: 'Mobile Number',
                              controller: _mobileController,
                              icon: Icons.phone_rounded,
                              isDark: isDark,
                              keyboardType: TextInputType.phone,
                              onChanged: (_) {
                                if (_isMobileVerified) {
                                  setState(() => _isMobileVerified = false);
                                }
                              },
                              trailingBadge: _isMobileVerified
                                  ? _buildStatusPill(
                                      label: 'Verified',
                                      icon: Icons.check_circle_rounded,
                                      color: const Color(0xFF10B981),
                                      bgColor: const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.12),
                                    )
                                  : _buildVerifyActionPill(
                                      label: _showMobileOtpField
                                          ? 'Close'
                                          : 'Verify',
                                      onTap: () {
                                        setState(() {
                                          _showMobileOtpField =
                                              !_showMobileOtpField;
                                        });
                                      },
                                    ),
                            ),
                            // In-place OTP field for Mobile
                            if (_showMobileOtpField && !_isMobileVerified) ...[
                              const SizedBox(height: 8),
                              _buildInlineOtpSection(
                                isDark: isDark,
                                targetTitle: 'Mobile Number',
                                targetValue: _mobileController.text,
                                controller: _mobileOtpController,
                                onConfirm: () {
                                  if (_mobileOtpController.text.trim().length >=
                                      4) {
                                    setState(() {
                                      _isMobileVerified = true;
                                      _showMobileOtpField = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Mobile number verified successfully!',
                                        ),
                                        backgroundColor: AppTheme.ok,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter 4-digit code (e.g. 1234)',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ══════════════════════════════════════════
                        // CARD 3: LOCATION & STATUS
                        // ══════════════════════════════════════════
                        _buildSectionCard(
                          isDark: isDark,
                          icon: Icons.location_on_rounded,
                          title: 'Location & Status',
                          showAccentLine: true,
                          children: [
                            Row(
                              children: [
                                // Country
                                Expanded(
                                  child: _buildDropdownSelector(
                                    label: 'Country',
                                    value: _selectedCountry,
                                    icon: Icons.language_rounded,
                                    items: _countryOptions,
                                    isDark: isDark,
                                    onChanged: (val) =>
                                        setState(() => _selectedCountry = val),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Status
                                Expanded(
                                  child: _buildDropdownSelector(
                                    label: 'Status',
                                    value: _isCustomStatus
                                        ? 'Custom'
                                        : _selectedStatus,
                                    customLeading: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    items: _statusPresetOptions,
                                    isDark: isDark,
                                    onChanged: (val) {
                                      if (val == 'Custom Status...') {
                                        setState(() {
                                          _isCustomStatus = true;
                                        });
                                      } else {
                                        setState(() {
                                          _isCustomStatus = false;
                                          _selectedStatus = val;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            // Custom Status Direct Input Field if user selected Custom
                            if (_isCustomStatus) ...[
                              const SizedBox(height: 10),
                              _buildFormField(
                                label: 'Write Custom Status',
                                controller: _customStatusController,
                                icon: Icons.edit_note_rounded,
                                isDark: isDark,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: Avatar Image ──
  Widget _buildAvatarImage(AppState appState) {
    if (appState.profilePhotoPath != null) {
      return Image.file(
        File(appState.profilePhotoPath!),
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildDefaultAvatar(),
      );
    }
    return Image.asset(
      'assets/images/home_page/user_avatar.jpg',
      fit: BoxFit.cover,
      errorBuilder: (ctx, err, stack) => _buildDefaultAvatar(),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF6366F1),
      child: const Center(
        child: Text(
          'S',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
      ),
    );
  }

  // ── Helper: Section Card Container ──
  Widget _buildSectionCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required List<Widget> children,
    bool showAccentLine = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF6366F1), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          if (showAccentLine) ...[
            const SizedBox(height: 4),
            Container(
              margin: const EdgeInsets.only(left: 28),
              width: 32,
              height: 2.2,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  void _editFieldValue({
    required String title,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    final tempController = TextEditingController(text: controller.text);
    final isDark = context.read<AppState>().isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(icon, color: const Color(0xFF6366F1), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Edit $title',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6366F1),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: TextField(
                      controller: tempController,
                      autofocus: true,
                      keyboardType: keyboardType,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter $title',
                        hintStyle: TextStyle(
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      onSubmitted: (val) {
                        setState(() {
                          controller.text = val.trim();
                          onChanged?.call(val.trim());
                        });
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        controller.text = tempController.text.trim();
                        onChanged?.call(tempController.text.trim());
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Helper: Styled Form Field (Rendered as clean box value, zero blue ovals or bubbles) ──
  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isDark,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
    Widget? trailingBadge,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: readOnly
              ? null
              : () => _editFieldValue(
                  title: label,
                  controller: controller,
                  icon: icon,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                ),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? (readOnly
                        ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                        : const Color(0xFF0F172A))
                  : (readOnly ? const Color(0xFFF8FAFC) : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? 'Enter $label' : controller.text,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: controller.text.isEmpty
                          ? (isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8))
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ?trailingBadge,
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Helper: Clickable Box (e.g. Date of Birth) ──
  Widget _buildClickableBox({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFF6366F1)),
                const SizedBox(width: 6),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Helper: Dropdown Selector Box (InkWell without ListTile) ──
  Widget _buildDropdownSelector({
    required String label,
    required String value,
    IconData? icon,
    Widget? customLeading,
    required List<String> items,
    required bool isDark,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (ctx) => SafeArea(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.55,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Select $label',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Material(
                            color: Colors.transparent,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: items.map((opt) {
                                final isSelected = opt == value;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    onChanged(opt);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 11,
                                    ),
                                    margin: const EdgeInsets.only(bottom: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(
                                              0xFF6366F1,
                                            ).withValues(alpha: 0.12)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            opt,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? const Color(0xFF6366F1)
                                                  : (isDark
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFF0F172A,
                                                          )),
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: Color(0xFF6366F1),
                                            size: 17,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                ?customLeading,
                if (icon != null)
                  Icon(icon, size: 15, color: const Color(0xFF6366F1)),
                const SizedBox(width: 4),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Helper: Inline In-place OTP Field Box ──
  Widget _buildInlineOtpSection({
    required bool isDark,
    required String targetTitle,
    required String targetValue,
    required TextEditingController controller,
    required VoidCallback onConfirm,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 15,
                color: Color(0xFF6366F1),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Enter 4-digit verification code sent to $targetTitle',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '••••',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helper: Status Pill Badge (Available / Verified) ──
  Widget _buildStatusPill({
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: Interactive Verify Action Pill ──
  Widget _buildVerifyActionPill({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ── Custom Beautiful Themed Date Picker (Image 3 fix) ──
  Future<void> _pickCustomDate(BuildContext context) async {
    final isDark = context.read<AppState>().isDarkMode;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2002, 4, 15),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: ColorScheme(
              brightness: isDark ? Brightness.dark : Brightness.light,
              primary: const Color(0xFF6366F1),
              onPrimary: Colors.white,
              secondary: const Color(0xFF8B5CF6),
              onSecondary: Colors.white,
              error: const Color(0xFFEF4444),
              onError: Colors.white,
              surface: isDark ? const Color(0xFF1E293B) : Colors.white,
              onSurface: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              elevation: 16,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final formatted =
          '${picked.day} ${months[picked.month - 1]} ${picked.year}';
      setState(() => _dobController.text = formatted);
    }
  }

  void _pickPhoto(BuildContext context, AppState appState) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await appState.setProfilePhotoPath(image.path);
    }
  }
}
