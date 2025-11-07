import psycopg2

# Database connection details
db_url = "postgresql://postgres.xsrvoyjdrylusvmdwppl:eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhzcnZveWpkcnlsdXN2bWR3cHBsIiwicm9sZSI6InBvc3RncmVzIiwiaWF0IjoxNzU4NTU0MDUwLCJleHAiOjIwNzQxMzAwNTB9.c7kD2ySbZzFJ2R4vBW5JNi0XHJWUaJeXDdVCuqy2_QY@aws-0-eu-central-1.pooler.supabase.com:6543/postgres"

try:
    print("Connecting to database...")
    conn = psycopg2.connect(db_url)
    cursor = conn.cursor()

    print("Adding source_language column...")
    cursor.execute("""
        ALTER TABLE chat_messages
        ADD COLUMN IF NOT EXISTS source_language TEXT NOT NULL DEFAULT 'en';
    """)

    print("Creating index...")
    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_chat_messages_source_language
        ON chat_messages(source_language);
    """)

    print("Updating existing messages...")
    cursor.execute("""
        UPDATE chat_messages
        SET source_language = 'en'
        WHERE source_language IS NULL OR source_language = '';
    """)

    conn.commit()
    cursor.close()
    conn.close()

    print("✅ Migration completed successfully!")

except Exception as e:
    print(f"❌ Error: {e}")
    raise
