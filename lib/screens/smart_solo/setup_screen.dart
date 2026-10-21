/// Setup screen for Smart Solo mode where users configure AI shooting preferences.
/// Allows users to select shooting goal (Travel, Portrait, Fashion), environment (Outdoor, Beach, Nature), and style (Full body, Half body, Headshot).
/// Uses user selections to generate personalized AI pose suggestions and capture instructions.
/// Bridge screen between mode selection and AI plan generation for customized smart capturing experience.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_shutter/core/providers/app_state.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/smart_solo/ai_plan_screen.dart';

class SmartSetupScreen extends StatefulWidget {
  const SmartSetupScreen({super.key});

  @override
  State<SmartSetupScreen> createState() => _SmartSetupScreenState();
}

class _SmartSetupScreenState extends State<SmartSetupScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isDark = appState.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Solo Setup', style: TextStyle(fontSize: 18, color: AppTheme.ink(isDark), fontWeight: FontWeight.bold)),
            Text('Tell AI what kind of shot you want', style: TextStyle(fontSize: 12, color: AppTheme.muted(isDark).withOpacity(0.9))),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.ink(isDark)),
      ),
      body: Container(
        decoration: AppTheme.gradientBg(isDark),
        child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildSelectionCard(isDark: isDark, 
                          title: 'What are you shooting for?',
                          options: ['Travel', 'Portrait', 'Fashion', 'Reel'],
                          selected: appState.selectedGoal,
                          onSelect: (val) => context.read<AppState>().setSetupOptions(goal: val),
                        ),
                        const SizedBox(height: 12),
                        _buildSelectionCard(isDark: isDark, 
                          title: 'Environment',
                          options: ['Outdoor City', 'Beach', 'Nature', 'Indoor Café'],
                          selected: appState.selectedEnv,
                          onSelect: (val) => context.read<AppState>().setSetupOptions(env: val),
                        ),
                        const SizedBox(height: 12),
                        _buildSelectionCard(isDark: isDark, 
                          title: 'Shot type & style',
                          options: ['Full body', 'Half body', 'Cinematic', 'Natural'],
                          selected: appState.selectedStyle,
                          onSelect: (val) => context.read<AppState>().setSetupOptions(style: val),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.brand.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AiPlanScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Generate AI Shoot Plan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildSelectionCard({required bool isDark,
    required String title,
    required List<String> options,
    required String selected,
    required Function(String) onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.glassmorphicDecoration(isDark),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.ink(isDark))),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final isSelected = opt == selected;
              return GestureDetector(
                onTap: () => onSelect(opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.brand.withOpacity(0.12) : Colors.white.withOpacity(0.05),
                    border: Border.all(
                      color: isSelected ? AppTheme.brand.withOpacity(0.4) : AppTheme.line(isDark),
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: isSelected
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            )
                          ],
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppTheme.brand : AppTheme.ink(isDark),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

