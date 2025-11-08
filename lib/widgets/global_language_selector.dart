import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../config/colors.dart';

class GlobalLanguageSelector extends StatelessWidget {
  const GlobalLanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final currentLanguage = languageProvider.currentLanguage;

        return PopupMenuButton<Language>(
          offset: const Offset(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryLight.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentLanguage.flag,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 6),
                Text(
                  currentLanguage.code.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
          itemBuilder: (context) {
            return LanguageProvider.supportedLanguages.map((language) {
              final isSelected = language.code == currentLanguage.code;

              return PopupMenuItem<Language>(
                value: language,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        language.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          language.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }).toList();
          },
          onSelected: (language) {
            languageProvider.setLanguage(language);
            
            // Show feedback to user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Text(language.flag, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text('Language changed to ${language.name}'),
                  ],
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
