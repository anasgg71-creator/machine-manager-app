-- Add source_language column to chat_messages table
ALTER TABLE chat_messages
ADD COLUMN IF NOT EXISTS source_language TEXT NOT NULL DEFAULT 'en';

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_chat_messages_source_language
ON chat_messages(source_language);

-- Update existing messages to have English as default language
UPDATE chat_messages
SET source_language = 'en'
WHERE source_language IS NULL OR source_language = '';
