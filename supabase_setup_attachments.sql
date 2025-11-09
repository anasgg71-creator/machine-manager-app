-- Create ticket_attachments table
CREATE TABLE IF NOT EXISTS public.ticket_attachments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    ticket_id UUID NOT NULL REFERENCES public.tickets(id) ON DELETE CASCADE,
    uploader_id UUID NOT NULL REFERENCES public.profiles(id),
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_type TEXT NOT NULL,
    file_size BIGINT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.ticket_attachments ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow authenticated users to read attachments" ON public.ticket_attachments;
DROP POLICY IF EXISTS "Allow authenticated users to upload attachments" ON public.ticket_attachments;

-- Create policy to allow authenticated users to read attachments
CREATE POLICY "Allow authenticated users to read attachments"
ON public.ticket_attachments FOR SELECT
TO authenticated
USING (true);

-- Create policy to allow authenticated users to upload attachments
CREATE POLICY "Allow authenticated users to upload attachments"
ON public.ticket_attachments FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = uploader_id);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_ticket_attachments_ticket_id ON public.ticket_attachments(ticket_id);
