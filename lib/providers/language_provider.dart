import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;
  String get currentLanguageCode => _currentLocale.languageCode;

  // Supported languages
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
    ),
    LanguageOption(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
    ),
    LanguageOption(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
    ),
    LanguageOption(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
    ),
    LanguageOption(
      code: 'de',
      name: 'German',
      nativeName: 'Deutsch',
      flag: '🇩🇪',
    ),
    LanguageOption(
      code: 'zh',
      name: 'Chinese',
      nativeName: '中文',
      flag: '🇨🇳',
    ),
    LanguageOption(
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
      flag: '🇯🇵',
    ),
    LanguageOption(
      code: 'ko',
      name: 'Korean',
      nativeName: '한국어',
      flag: '🇰🇷',
    ),
    LanguageOption(
      code: 'ru',
      name: 'Russian',
      nativeName: 'Русский',
      flag: '🇷🇺',
    ),
    LanguageOption(
      code: 'pt',
      name: 'Portuguese',
      nativeName: 'Português',
      flag: '🇵🇹',
    ),
    LanguageOption(
      code: 'it',
      name: 'Italian',
      nativeName: 'Italiano',
      flag: '🇮🇹',
    ),
    LanguageOption(
      code: 'hi',
      name: 'Hindi',
      nativeName: 'हिन्दी',
      flag: '🇮🇳',
    ),
  ];

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString('language_code');

      if (savedLanguageCode != null) {
        _currentLocale = Locale(savedLanguageCode);
        notifyListeners();
      }
    } catch (e) {
      // If loading fails, use default language
      debugPrint('Failed to load saved language: $e');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (_currentLocale.languageCode == languageCode) return;

    _currentLocale = Locale(languageCode);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', languageCode);
    } catch (e) {
      debugPrint('Failed to save language preference: $e');
    }
  }

  LanguageOption get currentLanguage {
    return supportedLanguages.firstWhere(
      (lang) => lang.code == _currentLocale.languageCode,
      orElse: () => supportedLanguages[0],
    );
  }

  // Translation helper (basic implementation)
  String translate(String key) {
    return _translations[_currentLocale.languageCode]?[key] ?? key;
  }

  // Basic translations map
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'profile': 'Profile',
      'settings': 'Settings',
      'account': 'Account',
      'preferences': 'Preferences',
      'language': 'Language',
      'notifications': 'Notifications',
      'privacy': 'Privacy',
      'about': 'About',
      'help': 'Help & Support',
      'logout': 'Logout',
      'edit_profile': 'Edit Profile',
      'change_password': 'Change Password',
      'full_name': 'Full Name',
      'email': 'Email',
      'role': 'Role',
      'points': 'Points',
      'solved': 'Solved',
      'rating': 'Rating',
      'tickets_solved': 'Tickets Solved',
      'average_rating': 'Average Rating',
      'badges': 'Badges',
      'badges_achievements': 'Badges & Achievements',
      'statistics': 'Statistics',
      'save': 'Save',
      'cancel': 'Cancel',
      'select_language': 'Select Language',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'push_notifications': 'Push Notifications',
      'email_notifications': 'Email Notifications',
      'ticket_updates': 'Ticket Updates',
      'app_version': 'App Version',
      'terms_of_service': 'Terms of Service',
      'privacy_policy': 'Privacy Policy',
      'update_personal_info': 'Update your personal information',
      'update_password': 'Update your password',
      'coming_soon': 'Coming soon',
      'receive_push': 'Receive push notifications',
      'receive_email': 'Receive email updates',
      'get_ticket_notifications': 'Get notified about ticket changes',
      'get_help': 'Get help or contact support',
      'read_terms': 'Read our terms',
      'read_privacy': 'Read our privacy policy',
      'logout_confirm': 'Are you sure you want to logout?',
      'language_changed': 'Language changed to',
      'account_settings': 'Account Settings',
      'reset_password': 'Reset Password',
      'reset_password_message': 'We will send a password reset link to your email address.',
      'send_reset_link': 'Send Reset Link',
      'profile_updated_success': 'Profile updated successfully',
      'profile_updated_failed': 'Failed to update profile',
      'password_reset_sent': 'Password reset link sent to your email',
      'password_reset_failed': 'Failed to send reset link',
      // Room names
      'tetra_support': 'Tetra Support',
      'tetra_support_desc': 'Technical Support & Assistance',
      'supplier_parts': 'Supplier Parts',
      'supplier_parts_desc': 'Parts and supplies',
      'quality_lab': 'Quality LAB',
      'quality_lab_desc': 'Quality control lab',
      'optirva_support': 'Optirva Support',
      'optirva_support_desc': 'Technical support',
      'machine_market': 'Machine Market',
      'machine_market_desc': 'Tetra Pak Equipment Sales',
      // Menu items
      'ask_question': 'Ask Question',
      'ask_question_desc': 'Get help from team',
      'report_problem': 'Report Problem',
      'report_problem_desc': 'Submit machine issues',
      'active_issues': 'Active Issues',
      'active_issues_desc': 'Current open tickets & discussions',
      'history': 'History',
      'history_desc': 'Past tickets and resolutions',
      'team': 'Team',
      'team_desc': 'Leaderboard & profiles',
      'machine_categories': 'Machine Categories',
      'machine_categories_desc': 'Browse by machine type',
      // Status
      'status_running': 'Running',
      'status_active': 'Active',
      'status_available': 'Available',
      'status_open': 'Open',
    },
    'ar': {
      'profile': 'الملف الشخصي',
      'settings': 'الإعدادات',
      'account': 'الحساب',
      'preferences': 'التفضيلات',
      'language': 'اللغة',
      'notifications': 'الإشعارات',
      'privacy': 'الخصوصية',
      'about': 'حول',
      'help': 'المساعدة والدعم',
      'logout': 'تسجيل الخروج',
      'edit_profile': 'تعديل الملف الشخصي',
      'change_password': 'تغيير كلمة المرور',
      'full_name': 'الاسم الكامل',
      'email': 'البريد الإلكتروني',
      'role': 'الدور',
      'points': 'النقاط',
      'solved': 'محلول',
      'rating': 'التقييم',
      'tickets_solved': 'التذاكر المحلولة',
      'average_rating': 'متوسط التقييم',
      'badges': 'الشارات',
      'badges_achievements': 'الشارات والإنجازات',
      'statistics': 'الإحصائيات',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'select_language': 'اختر اللغة',
      'theme': 'المظهر',
      'dark_mode': 'الوضع الداكن',
      'push_notifications': 'إشعارات الدفع',
      'email_notifications': 'إشعارات البريد الإلكتروني',
      'ticket_updates': 'تحديثات التذاكر',
      'app_version': 'إصدار التطبيق',
      'terms_of_service': 'شروط الخدمة',
      'privacy_policy': 'سياسة الخصوصية',
      'update_personal_info': 'قم بتحديث معلوماتك الشخصية',
      'update_password': 'قم بتحديث كلمة المرور الخاصة بك',
      'coming_soon': 'قريباً',
      'receive_push': 'تلقي إشعارات الدفع',
      'receive_email': 'تلقي تحديثات البريد الإلكتروني',
      'get_ticket_notifications': 'احصل على إشعارات حول تغييرات التذاكر',
      'get_help': 'احصل على المساعدة أو اتصل بالدعم',
      'read_terms': 'اقرأ شروطنا',
      'read_privacy': 'اقرأ سياسة الخصوصية الخاصة بنا',
      'logout_confirm': 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
      'language_changed': 'تم تغيير اللغة إلى',
      'account_settings': 'إعدادات الحساب',
      'reset_password': 'إعادة تعيين كلمة المرور',
      'reset_password_message': 'سنرسل رابط إعادة تعيين كلمة المرور إلى عنوان بريدك الإلكتروني.',
      'send_reset_link': 'إرسال رابط إعادة التعيين',
      'profile_updated_success': 'تم تحديث الملف الشخصي بنجاح',
      'profile_updated_failed': 'فشل تحديث الملف الشخصي',
      'password_reset_sent': 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
      'password_reset_failed': 'فشل إرسال رابط إعادة التعيين',
      // Room names
      'tetra_support': 'دعم تترا',
      'tetra_support_desc': 'الدعم الفني والمساعدة',
      'supplier_parts': 'قطع الموردين',
      'supplier_parts_desc': 'قطع الغيار والمستلزمات',
      'quality_lab': 'مختبر الجودة',
      'quality_lab_desc': 'مختبر مراقبة الجودة',
      'optirva_support': 'دعم أوبتيرفا',
      'optirva_support_desc': 'الدعم الفني',
      'machine_market': 'سوق الآلات',
      'machine_market_desc': 'مبيعات معدات تترا باك',
      // Menu items
      'ask_question': 'اطرح سؤالاً',
      'ask_question_desc': 'احصل على المساعدة من الفريق',
      'report_problem': 'أبلغ عن مشكلة',
      'report_problem_desc': 'أرسل مشكلات الآلات',
      'active_issues': 'المشاكل النشطة',
      'active_issues_desc': 'التذاكر المفتوحة والمناقشات الحالية',
      'history': 'السجل',
      'history_desc': 'التذاكر والحلول السابقة',
      'team': 'الفريق',
      'team_desc': 'لوحة المتصدرين والملفات الشخصية',
      'machine_categories': 'فئات الآلات',
      'machine_categories_desc': 'تصفح حسب نوع الآلة',
      // Status
      'status_running': 'قيد التشغيل',
      'status_active': 'نشط',
      'status_available': 'متاح',
      'status_open': 'مفتوح',
    },
    'es': {
      'profile': 'Perfil',
      'settings': 'Configuración',
      'account': 'Cuenta',
      'preferences': 'Preferencias',
      'language': 'Idioma',
      'notifications': 'Notificaciones',
      'privacy': 'Privacidad',
      'about': 'Acerca de',
      'help': 'Ayuda y Soporte',
      'logout': 'Cerrar Sesión',
      'edit_profile': 'Editar Perfil',
      'change_password': 'Cambiar Contraseña',
      'full_name': 'Nombre Completo',
      'email': 'Correo Electrónico',
      'role': 'Rol',
      'points': 'Puntos',
      'solved': 'Resueltos',
      'rating': 'Calificación',
      'tickets_solved': 'Tickets Resueltos',
      'average_rating': 'Calificación Promedio',
      'badges': 'Insignias',
      'badges_achievements': 'Insignias y Logros',
      'statistics': 'Estadísticas',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'select_language': 'Seleccionar Idioma',
      'theme': 'Tema',
      'dark_mode': 'Modo Oscuro',
      'push_notifications': 'Notificaciones Push',
      'email_notifications': 'Notificaciones por Correo',
      'ticket_updates': 'Actualizaciones de Tickets',
      'app_version': 'Versión de la App',
      'terms_of_service': 'Términos de Servicio',
      'privacy_policy': 'Política de Privacidad',
      'update_personal_info': 'Actualiza tu información personal',
      'update_password': 'Actualiza tu contraseña',
      'coming_soon': 'Próximamente',
      'receive_push': 'Recibir notificaciones push',
      'receive_email': 'Recibir actualizaciones por correo',
      'get_ticket_notifications': 'Recibir notificaciones sobre cambios en tickets',
      'get_help': 'Obtener ayuda o contactar soporte',
      'read_terms': 'Leer nuestros términos',
      'read_privacy': 'Leer nuestra política de privacidad',
      'logout_confirm': '¿Estás seguro de que quieres cerrar sesión?',
      'language_changed': 'Idioma cambiado a',
      'account_settings': 'Configuración de Cuenta',
      'reset_password': 'Restablecer Contraseña',
      'reset_password_message': 'Te enviaremos un enlace para restablecer tu contraseña a tu correo electrónico.',
      'send_reset_link': 'Enviar Enlace de Restablecimiento',
      'profile_updated_success': 'Perfil actualizado con éxito',
      'profile_updated_failed': 'Error al actualizar el perfil',
      'password_reset_sent': 'Enlace de restablecimiento enviado a tu correo',
      'password_reset_failed': 'Error al enviar el enlace',
      // Room names
      'tetra_support': 'Soporte Tetra',
      'tetra_support_desc': 'Soporte Técnico y Asistencia',
      'supplier_parts': 'Piezas de Proveedores',
      'supplier_parts_desc': 'Piezas y suministros',
      'quality_lab': 'Laboratorio de Calidad',
      'quality_lab_desc': 'Laboratorio de control de calidad',
      'optirva_support': 'Soporte Optirva',
      'optirva_support_desc': 'Soporte técnico',
      'machine_market': 'Mercado de Máquinas',
      'machine_market_desc': 'Ventas de Equipos Tetra Pak',
      // Menu items
      'ask_question': 'Hacer Pregunta',
      'ask_question_desc': 'Obtener ayuda del equipo',
      'report_problem': 'Reportar Problema',
      'report_problem_desc': 'Enviar problemas de máquinas',
      'active_issues': 'Problemas Activos',
      'active_issues_desc': 'Tickets abiertos y discusiones actuales',
      'history': 'Historial',
      'history_desc': 'Tickets y resoluciones pasadas',
      'team': 'Equipo',
      'team_desc': 'Tabla de clasificación y perfiles',
      'machine_categories': 'Categorías de Máquinas',
      'machine_categories_desc': 'Explorar por tipo de máquina',
      // Status
      'status_running': 'En ejecución',
      'status_active': 'Activo',
      'status_available': 'Disponible',
      'status_open': 'Abierto',
    },
    'fr': {
      'profile': 'Profil',
      'settings': 'Paramètres',
      'account': 'Compte',
      'preferences': 'Préférences',
      'language': 'Langue',
      'notifications': 'Notifications',
      'privacy': 'Confidentialité',
      'about': 'À propos',
      'help': 'Aide et Support',
      'logout': 'Déconnexion',
      'edit_profile': 'Modifier le Profil',
      'change_password': 'Changer le Mot de Passe',
      'full_name': 'Nom Complet',
      'email': 'Email',
      'role': 'Rôle',
      'points': 'Points',
      'solved': 'Résolus',
      'rating': 'Note',
      'tickets_solved': 'Tickets Résolus',
      'average_rating': 'Note Moyenne',
      'badges': 'Badges',
      'badges_achievements': 'Badges et Réalisations',
      'statistics': 'Statistiques',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'select_language': 'Sélectionner la Langue',
      'theme': 'Thème',
      'dark_mode': 'Mode Sombre',
      'push_notifications': 'Notifications Push',
      'email_notifications': 'Notifications Email',
      'ticket_updates': 'Mises à jour des Tickets',
      'app_version': 'Version de l\'Application',
      'terms_of_service': 'Conditions d\'Utilisation',
      'privacy_policy': 'Politique de Confidentialité',
      'update_personal_info': 'Mettez à jour vos informations personnelles',
      'update_password': 'Mettez à jour votre mot de passe',
      'coming_soon': 'Bientôt disponible',
      'receive_push': 'Recevoir des notifications push',
      'receive_email': 'Recevoir des mises à jour par email',
      'get_ticket_notifications': 'Être notifié des changements de tickets',
      'get_help': 'Obtenir de l\'aide ou contacter le support',
      'read_terms': 'Lire nos conditions',
      'read_privacy': 'Lire notre politique de confidentialité',
      'logout_confirm': 'Êtes-vous sûr de vouloir vous déconnecter?',
      'language_changed': 'Langue changée en',
      'account_settings': 'Paramètres du Compte',
      'reset_password': 'Réinitialiser le Mot de Passe',
      'reset_password_message': 'Nous enverrons un lien de réinitialisation à votre adresse email.',
      'send_reset_link': 'Envoyer le Lien de Réinitialisation',
      'profile_updated_success': 'Profil mis à jour avec succès',
      'profile_updated_failed': 'Échec de la mise à jour du profil',
      'password_reset_sent': 'Lien de réinitialisation envoyé à votre email',
      'password_reset_failed': 'Échec de l\'envoi du lien',
      // Room names
      'tetra_support': 'Support Tetra',
      'tetra_support_desc': 'Support Technique et Assistance',
      'supplier_parts': 'Pièces Fournisseurs',
      'supplier_parts_desc': 'Pièces et fournitures',
      'quality_lab': 'Laboratoire Qualité',
      'quality_lab_desc': 'Laboratoire de contrôle qualité',
      'optirva_support': 'Support Optirva',
      'optirva_support_desc': 'Support technique',
      'machine_market': 'Marché des Machines',
      'machine_market_desc': 'Ventes d\'Équipements Tetra Pak',
      // Menu items
      'ask_question': 'Poser une Question',
      'ask_question_desc': 'Obtenir de l\'aide de l\'équipe',
      'report_problem': 'Signaler un Problème',
      'report_problem_desc': 'Soumettre des problèmes de machines',
      'active_issues': 'Problèmes Actifs',
      'active_issues_desc': 'Tickets ouverts et discussions en cours',
      'history': 'Historique',
      'history_desc': 'Tickets et résolutions passés',
      'team': 'Équipe',
      'team_desc': 'Classement et profils',
      'machine_categories': 'Catégories de Machines',
      'machine_categories_desc': 'Parcourir par type de machine',
      // Status
      'status_running': 'En cours',
      'status_active': 'Actif',
      'status_available': 'Disponible',
      'status_open': 'Ouvert',
    },
  };
}

class LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}
