# Auto-Translation Feature - Complete Code Implementation

## ✅ COMPLETED:
1. Translation Service (`lib/services/translation_service.dart`) - DONE
2. Database Migration SQL - DONE
3. Translator package added - DONE

## 📝 REMAINING IMPLEMENTATIONS:

### 1. Update UserProfile Model
**File:** `lib/models/user_profile.dart`

Add this property to the UserProfile class:
```dart
final String preferredReceiveLanguage;
```

Update constructor:
```dart
UserProfile({
  // ... existing parameters
  this.preferredReceiveLanguage = 'en',
});
```

Update fromJson:
```dart
preferredReceiveLanguage: json['preferred_receive_language'] ?? 'en',
```

Update toJson:
```dart
'preferred_receive_language': preferredReceiveLanguage,
```

Update copyWith:
```dart
String? preferredReceiveLanguage,
// ...
preferredReceiveLanguage: preferredReceiveLanguage ?? this.preferredReceiveLanguage,
```

---

### 2. Update ChatMessage Model
**File:** `lib/models/chat_message.dart`

Add these properties:
```dart
final String originalText;
final String originalLang;
final Map<String, dynamic>? translations;
```

Update constructor:
```dart
ChatMessage({
  // ... existing parameters
  required this.originalText,
  required this.originalLang,
  this.translations,
});
```

Update fromJson:
```dart
originalText: json['original_text'] ?? json['message'] ?? '',
originalLang: json['original_lang'] ?? 'en',
translations: json['translations'] as Map<String, dynamic>?,
```

Update toJson:
```dart
'original_text': originalText,
'original_lang': originalLang,
'translations': translations,
```

---

### 3. Update SupabaseService - Add Translation Methods
**File:** `lib/services/supabase_service.dart`

Add import:
```dart
import 'translation_service.dart';
```

Add method to update user language preference:
```dart
Future<void> updateUserLanguagePreference(String userId, String languageCode) async {
  try {
    print('🌐 Updating language preference to $languageCode for user $userId');
    await client
        .from('profiles')
        .update({'preferred_receive_language': languageCode})
        .eq('id', userId);
    print('✅ Language preference updated successfully');
  } catch (e) {
    print('❌ Error updating language preference: $e');
    rethrow;
  }
}
```

Modify sendMessage to include translation:
```dart
Future<void> sendChatMessage({
  required String ticketId,
  required String message,
  required String senderId,
}) async {
  try {
    final translationService = TranslationService();

    // 1. Detect language of the message
    final detectedLang = await translationService.detectLanguage(message);
    print('🌐 Detected language: $detectedLang');

    // 2. Get recipient's preferred language
    // (You'll need to pass ticket participants or fetch them)
    // For now, we'll just store original and let display handle translation

    // 3. Send message with original text and language
    await client.from('chat_messages').insert({
      'ticket_id': ticketId,
      'sender_id': senderId,
      'message': message, // Keep for backward compatibility
      'original_text': message,
      'original_lang': detectedLang,
      'translations': {}, // Empty initially, will be populated on-demand
      'created_at': DateTime.now().toIso8601String(),
    });

    print('✅ Message sent with translation metadata');
  } catch (e) {
    print('❌ Error sending message: $e');
    rethrow;
  }
}
```

Add method to get translated messages:
```dart
Future<List<ChatMessage>> getTranslatedMessages({
  required String ticketId,
  required String userId,
}) async {
  try {
    // 1. Get user's preferred language
    final userProfile = await client
        .from('profiles')
        .select('preferred_receive_language')
        .eq('id', userId)
        .single();

    final preferredLang = userProfile['preferred_receive_language'] ?? 'en';
    print('🌐 User preferred language: $preferredLang');

    // 2. Get all messages for the ticket
    final response = await client
        .from('chat_messages')
        .select('*, sender:profiles!chat_messages_sender_id_fkey(*)')
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true);

    final List<ChatMessage> messages = [];
    final translationService = TranslationService();

    // 3. Process each message
    for (final json in response) {
      final originalText = json['original_text'] ?? json['message'] ?? '';
      final originalLang = json['original_lang'] ?? 'en';
      final cachedTranslations = json['translations'] as Map<String, dynamic>?;

      // 4. Check if we need to translate
      String displayText = originalText;
      if (originalLang != preferredLang) {
        // Check cache first
        if (cachedTranslations != null && cachedTranslations.containsKey(preferredLang)) {
          displayText = cachedTranslations[preferredLang];
          print('✅ Using cached translation');
        } else {
          // Translate on-the-fly
          print('🌐 Translating message on-the-fly');
          displayText = await translationService.translate(
            text: originalText,
            from: originalLang,
            to: preferredLang,
          );

          // Update cache in background (fire and forget)
          _cacheTranslation(json['id'], preferredLang, displayText);
        }
      }

      // Create message with translated text
      json['message'] = displayText; // Override message with translation
      messages.add(ChatMessage.fromJson(json));
    }

    return messages;
  } catch (e) {
    print('❌ Error getting translated messages: $e');
    rethrow;
  }
}

// Helper method to cache translation (fire and forget)
void _cacheTranslation(String messageId, String lang, String translation) {
  client.from('chat_messages').update({
    'translations': {lang: translation}
  }).eq('id', messageId).then((_) {
    print('✅ Translation cached for language: $lang');
  }).catchError((e) {
    print('⚠️ Failed to cache translation: $e');
  });
}
```

---

### 4. Create Language Selector Widget
**File:** `lib/widgets/language_selector.dart`

```dart
import 'package:flutter/material.dart';
import 'package:machine_manager_app/config/colors.dart';
import 'package:machine_manager_app/services/translation_service.dart';

class LanguageSelector extends StatelessWidget {
  final String currentLanguage;
  final Function(String) onLanguageChanged;

  const LanguageSelector({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final translationService = TranslationService();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLanguage,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          isDense: true,
          onChanged: (String? newValue) {
            if (newValue != null) {
              onLanguageChanged(newValue);
            }
          },
          items: TranslationService.supportedLanguages.entries
              .map((entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          translationService.getLanguageFlag(entry.key),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
```

---

### 5. Update Chat Screen
**File:** `lib/screens/chat/chat_screen.dart`

Add imports:
```dart
import 'package:machine_manager_app/widgets/language_selector.dart';
import 'package:machine_manager_app/services/translation_service.dart';
```

Add state variable:
```dart
String _userPreferredLanguage = 'en';
bool _showOriginal = false; // Toggle to show original text
```

In initState, load user's language preference:
```dart
@override
void initState() {
  super.initState();
  _loadUserLanguagePreference();
  _loadMessages();
}

Future<void> _loadUserLanguagePreference() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final userProfile = authProvider.userProfile;
  if (userProfile != null) {
    setState(() {
      _userPreferredLanguage = userProfile.preferredReceiveLanguage;
    });
  }
}
```

Add language selector to AppBar:
```dart
appBar: AppBar(
  title: Text(widget.ticket.title),
  actions: [
    LanguageSelector(
      currentLanguage: _userPreferredLanguage,
      onLanguageChanged: (newLang) async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.userProfile?.id;
        if (userId != null) {
          await SupabaseService().updateUserLanguagePreference(userId, newLang);
          setState(() {
            _userPreferredLanguage = newLang;
          });
          _loadMessages(); // Reload with new language
        }
      },
    ),
    const SizedBox(width: 16),
  ],
),
```

Replace _loadMessages with translated version:
```dart
Future<void> _loadMessages() async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final userId = authProvider.userProfile?.id;
  if (userId == null) return;

  final messages = await SupabaseService().getTranslatedMessages(
    ticketId: widget.ticket.id,
    userId: userId,
  );

  setState(() {
    _messages = messages;
  });
}
```

Add original language badge to message bubble:
```dart
// In _buildMessageBubble, add this after message text:
if (message.originalLang != _userPreferredLanguage)
  GestureDetector(
    onTap: () {
      // Toggle between original and translated
      setState(() {
        _showOriginal = !_showOriginal;
      });
    },
    child: Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            TranslationService().getLanguageFlag(message.originalLang),
            style: const TextStyle(fontSize: 10),
          ),
          const SizedBox(width: 4),
          Text(
            'Original',
            style: TextStyle(
              fontSize: 10,
              color: isMe ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  ),
```

---

## 🔧 DATABASE MIGRATION

**IMPORTANT:** Run this in Supabase SQL Editor first:

```sql
-- File: supabase/migrations/20250118_add_translation_support.sql
-- Copy and paste into: https://supabase.com/dashboard/project/xsrvoyjdrylusvmdwppl/sql/new

-- Add preferred_receive_language to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS preferred_receive_language VARCHAR(10) DEFAULT 'en';

-- Add translation columns to chat_messages table
ALTER TABLE chat_messages
ADD COLUMN IF NOT EXISTS original_text TEXT,
ADD COLUMN IF NOT EXISTS original_lang VARCHAR(10),
ADD COLUMN IF NOT EXISTS translations JSONB DEFAULT '{}'::jsonb;

-- Migrate existing messages
UPDATE chat_messages
SET original_text = message,
    original_lang = 'en'
WHERE original_text IS NULL;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_chat_messages_original_lang ON chat_messages(original_lang);
CREATE INDEX IF NOT EXISTS idx_profiles_receive_language ON profiles(preferred_receive_language);
```

---

## 🎯 TESTING STEPS

1. Run database migration in Supabase
2. Update all model files as specified
3. Update SupabaseService with translation methods
4. Create LanguageSelector widget
5. Update ChatScreen with language selector
6. Test with two users:
   - User A sets language to Arabic
   - User B sets language to English
   - User A sends "مرحبا" → User B sees "Hello"
   - User B sends "Hi there" → User A sees Arabic translation
7. Verify original language badge appears
8. Verify tapping badge shows original text

---

## 📊 SUMMARY

**Total Files to Modify:** 5
1. ✅ lib/services/translation_service.dart (CREATED)
2. lib/models/user_profile.dart (UPDATE)
3. lib/models/chat_message.dart (UPDATE)
4. lib/services/supabase_service.dart (UPDATE)
5. lib/widgets/language_selector.dart (CREATE)
6. lib/screens/chat/chat_screen.dart (UPDATE)

**Database:** 1 migration to run

**Result:** Fully automatic translation system with 26 language support!
