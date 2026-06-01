import 'package:flutter/material.dart';
import 'package:smart_shutter/core/theme.dart';
import 'package:smart_shutter/screens/smart_solo/ai_plan_screen.dart';

class SmartSetupScreen extends StatefulWidget {
  const SmartSetupScreen({super.key});

  @override
  State<SmartSetupScreen> createState() => _SmartSetupScreenState();
}

class _SmartSetupScreenState extends State<SmartSetupScreen> {
  String _selectedGoal = 'Travel';
  String _selectedEnv = 'Outdoor City';
  String _selectedStyle = 'Full body';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Smart Solo Setup', style: TextStyle(fontSize: 18, color: AppTheme.ink, fontWeight: FontWeight.bold)),
            Text('Tell AI what kind of shot you want', style: TextStyle(fontSize: 12, color: AppTheme.muted)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.ink),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSelectionCard(
              title: 'What are you shooting for?',
              options: ['Travel', 'Portrait', 'Fashion', 'Reel'],
              selected: _selectedGoal,
              onSelect: (val) => setState(() => _selectedGoal = val),
            ),
            const SizedBox(height: 12),
            _buildSelectionCard(
              title: 'Environment',
              options: ['Outdoor City', 'Beach', 'Nature', 'Indoor Café'],
              selected: _selectedEnv,
              onSelect: (val) => setState(() => _selectedEnv = val),
            ),
            const SizedBox(height: 12),
            _buildSelectionCard(
              title: 'Shot type & style',
              options: ['Full body', 'Half body', 'Cinematic', 'Natural'],
              selected: _selectedStyle,
              onSelect: (val) => setState(() => _selectedStyle = val),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const AiPlanScreen())
                  );
                },
                child: const Text('Generate AI Shoot Plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required List<String> options,
    required String selected,
    required Function(String) onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(20),
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final isSelected = opt == selected;
              return GestureDetector(
                onTap: () => onSelect(opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.brand.withOpacity(0.1) : Colors.white,
                    border: Border.all(color: isSelected ? AppTheme.brand.withOpacity(0.35) : AppTheme.line),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    opt, 
                    style: TextStyle(
                      fontSize: 12, 
                      color: isSelected ? AppTheme.brand : AppTheme.ink,
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
