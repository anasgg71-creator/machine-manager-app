# Auto-Translation Feature Implementation Guide

## Overview
Complete implementation of automatic message translation for ticket chat system.

## Architecture

### Database Changes
**File:** `supabase/migrations/20250118_add_translation_support.sql`

**Changes to `profiles` table:**
- `preferred_receive_language` VARCHAR(10) DEFAULT 'en'

**Changes to `chat_messages` table:**
- `original_text` TEXT - stores the original message
- `original_lang` VARCHAR(10) - ISO 639-1 language code
- `translations` JSONB - cached translations as JSON object

**Indexes:**
- `idx_chat_messages_original_lang`
- `idx_profiles_receive_language`

### Translation Flow

1. **User A writes message in Arabic:**
   - Detect language → 'ar'
   - Store: original_text="مرحبا", original_lang="ar"
   - Get User B's preferred_receive_language → 'en'
   - Translate to English → "Hello"
   - Cache translation in translations JSON: {"en": "Hello"}
   - User B sees "Hello"

2. **User B replies in English:**
   - Detect language → 'en'
   - Store: original_text="Hi there", original_lang="en"
   - Get User A's preferred_receive_language → 'ar'
   - Translate to Arabic → "مرحبا هناك"
   - Cache: {"ar": "مرحبا هناك"}
   - User A sees "مرحبا هناك"

## Implementation Steps

### Step 1: Run Database Migration
```sql
-- Copy content from supabase/migrations/20250118_add_translation_support.sql
-- Paste in Supabase SQL Editor at:
-- https://supabase.com/dashboard/project/xsrvoyjdrylusvmdwppl/sql/new
```

### Step 2: Translation Service
**File:** `lib/services/translation_service.dart`
- Uses Google Translator package
- Supports 26 languages
- Auto-detects source language
- Caches translations in JSONB

### Step 3: Update Models
**UserProfile model** - add:
```dart
String preferredReceiveLanguage; // ISO 639-1 code
```

**ChatMessage model** - add:
```dart
String originalText;
String originalLang;
Map<String, dynamic>? translations;
```

### Step 4: Update SupabaseService
**sendMessage method:**
1. Detect language of message
2. Store original_text and original_lang
3. Fetch recipient's preferred_receive_language
4. Translate message to recipient's language
5. Cache translation in translations JSON

**getMessages method:**
1. Fetch current user's preferred_receive_language
2. For each message, check if translation exists in cache
3. If not cached, translate on-the-fly
4. Display translated version

### Step 5: Update Chat UI
**Add language selector:**
- Dropdown at top of chat screen
- Shows current language with flag/icon
- Updates user's preferred_receive_language in profiles table
- Triggers re-render of messages with new language

**Message display:**
- Show translated text by default
- Small badge showing original language
- Tap badge to toggle between original and translated

## Supported Languages
English (en), Arabic (ar), Spanish (es), French (fr), German (de), Italian (it), Portuguese (pt), Russian (ru), Chinese (zh), Japanese (ja), Korean (ko), Hindi (hi), Turkish (tr), Dutch (nl), Polish (pl), Swedish (sv), Norwegian (no), Danish (da), Finnish (fi), Czech (cs), Greek (el), Hebrew (he), Thai (th), Vietnamese (vi), Indonesian (id), Malay (ms)

## Key Features
- ✅ Automatic language detection
- ✅ Real-time translation
- ✅ Translation caching for performance
- ✅ 26 language support
- ✅ No manual user action required
- ✅ Fallback to original on error
- ✅ Per-user language preference
- ✅ Original text always preserved

## Testing Checklist
- [ ] User A sends Arabic message, User B sees English
- [ ] User B sends English message, User A sees Arabic
- [ ] Language selector updates preference in database
- [ ] Cached translations load faster than first-time
- [ ] Original language badge shows correctly
- [ ] Tap original language badge to see original text
- [ ] Error handling when translation API fails
- [ ] Multi-user chat with different languages

## Performance Considerations
- Translations cached in JSONB for fast retrieval
- Indexed language columns for quick queries
- Translation happens async, doesn't block UI
- Fallback to original text prevents errors

## Future Enhancements
- Voice message translation
- Image text translation (OCR)
- Translation confidence scores
- Dialect support
- Offline translation caching
