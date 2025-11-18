-- Add preferred_receive_language to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS preferred_receive_language VARCHAR(10) DEFAULT 'en';

-- Add translation columns to chat_messages table
ALTER TABLE chat_messages
ADD COLUMN IF NOT EXISTS original_text TEXT,
ADD COLUMN IF NOT EXISTS original_lang VARCHAR(10),
ADD COLUMN IF NOT EXISTS translations JSONB DEFAULT '{}'::jsonb;

-- Migrate existing messages to new schema
-- Copy existing message content to original_text
UPDATE chat_messages
SET original_text = message,
    original_lang = 'en'
WHERE original_text IS NULL;

-- Create index for faster translation lookups
CREATE INDEX IF NOT EXISTS idx_chat_messages_original_lang ON chat_messages(original_lang);
CREATE INDEX IF NOT EXISTS idx_profiles_receive_language ON profiles(preferred_receive_language);

-- Add comment to document the schema
COMMENT ON COLUMN profiles.preferred_receive_language IS 'User preferred language for receiving translated messages (ISO 639-1 code)';
COMMENT ON COLUMN chat_messages.original_text IS 'Original message text before translation';
COMMENT ON COLUMN chat_messages.original_lang IS 'Original message language (ISO 639-1 code)';
COMMENT ON COLUMN chat_messages.translations IS 'Cached translations in JSON format: {"en": "Hello", "ar": "مرحبا", ...}';
