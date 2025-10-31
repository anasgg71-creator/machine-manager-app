import 'package:flutter/material.dart';
import '../config/colors.dart';

class FishboneDiagram extends StatefulWidget {
  final List<String>? initialAnalysis;
  final Function(List<String>) onAnalysisChanged;

  const FishboneDiagram({
    Key? key,
    this.initialAnalysis,
    required this.onAnalysisChanged,
  }) : super(key: key);

  @override
  State<FishboneDiagram> createState() => _FishboneDiagramState();
}

class _FishboneDiagramState extends State<FishboneDiagram> {
  final Map<String, List<String>> selectedCauses = {
    'man': [],
    'machine': [],
    'method': [],
    'material': [],
    'measurement': [],
    'environment': [],
  };

  final Map<String, TextEditingController> customControllers = {
    'man': TextEditingController(),
    'machine': TextEditingController(),
    'method': TextEditingController(),
    'material': TextEditingController(),
    'measurement': TextEditingController(),
    'environment': TextEditingController(),
  };

  final Map<String, List<String>> predefinedCauses = {
    'man': ['Insufficient training', 'Operator inexperience', 'Poor communication'],
    'machine': ['Worn/damaged parts', 'Poor calibration', 'Equipment age'],
    'method': ['Incorrect procedure', 'Missing documentation', 'No standard process'],
    'material': ['Poor material quality', 'Supplier issue', 'Improper storage'],
    'measurement': ['Measurement accuracy', 'Faulty measuring tools', 'Infrequent checks'],
    'environment': ['Temperature/humidity', 'Cleanliness issues', 'Vibration/noise'],
  };

  @override
  void initState() {
    super.initState();
    _loadInitialAnalysis();
  }

  void _loadInitialAnalysis() {
    if (widget.initialAnalysis != null) {
      for (var cause in widget.initialAnalysis!) {
        // Parse format "CATEGORY: Value"
        final parts = cause.split(': ');
        if (parts.length == 2) {
          final category = parts[0].toLowerCase();
          final value = parts[1];

          if (selectedCauses.containsKey(category)) {
            // Check if it's a predefined cause
            if (predefinedCauses[category]!.contains(value)) {
              selectedCauses[category]!.add(value);
            } else {
              // Custom cause
              customControllers[category]!.text = value;
            }
          }
        }
      }
      setState(() {});
    }
  }

  void _updateAnalysis() {
    List<String> analysis = [];

    selectedCauses.forEach((category, causes) {
      for (var cause in causes) {
        analysis.add('${category.toUpperCase()}: $cause');
      }

      // Add custom cause if exists
      final customText = customControllers[category]!.text.trim();
      if (customText.isNotEmpty) {
        analysis.add('${category.toUpperCase()}: $customText');
      }
    });

    widget.onAnalysisChanged(analysis);
  }

  @override
  void dispose() {
    customControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8F9FF), Colors.white],
        ),
        border: Border.all(color: AppColors.secondaryLight, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                '🐟 Root Cause Analysis (Fishbone Diagram)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Help identify potential root causes to make the issue clearer for the support team',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Top Row (Man, Machine, Method)
          _buildCategory('👷 MAN (People)', 'man'),
          const SizedBox(height: 12),
          _buildCategory('⚙️ MACHINE', 'machine'),
          const SizedBox(height: 12),
          _buildCategory('📋 METHOD', 'method'),
          const SizedBox(height: 24),

          // Center Spine
          _buildSpine(),
          const SizedBox(height: 24),

          // Bottom Row (Material, Measurement, Environment)
          _buildCategory('📦 MATERIAL', 'material'),
          const SizedBox(height: 12),
          _buildCategory('📏 MEASUREMENT', 'measurement'),
          const SizedBox(height: 12),
          _buildCategory('🌡️ ENVIRONMENT', 'environment'),

          // Summary
          if (_getTotalSelected() > 0) ...[
            const SizedBox(height: 20),
            _buildSummary(),
          ],
        ],
      ),
    );
  }

  Widget _buildCategory(String title, String category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Title
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Causes Container
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Predefined causes
              ...predefinedCauses[category]!.map((cause) => _buildCheckbox(category, cause)),

              // Custom input
              const SizedBox(height: 8),
              TextField(
                controller: customControllers[category],
                decoration: InputDecoration(
                  hintText: 'Other cause...',
                  hintStyle: const TextStyle(fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                style: const TextStyle(fontSize: 13),
                onChanged: (value) => _updateAnalysis(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox(String category, String cause) {
    final isSelected = selectedCauses[category]!.contains(cause);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedCauses[category]!.remove(cause);
          } else {
            selectedCauses[category]!.add(cause);
          }
        });
        _updateAnalysis();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                cause,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpine() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            children: [
              Text(
                '▶',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              SizedBox(width: 8),
              Text(
                'PROBLEM EFFECT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    List<String> allSelected = [];

    selectedCauses.forEach((category, causes) {
      for (var cause in causes) {
        allSelected.add('${category.toUpperCase()}: $cause');
      }

      final customText = customControllers[category]!.text.trim();
      if (customText.isNotEmpty) {
        allSelected.add('${category.toUpperCase()}: $customText');
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 Selected Root Causes:',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...allSelected.map((cause) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $cause',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  int _getTotalSelected() {
    int total = 0;
    selectedCauses.forEach((category, causes) {
      total += causes.length;
      if (customControllers[category]!.text.trim().isNotEmpty) {
        total++;
      }
    });
    return total;
  }
}
