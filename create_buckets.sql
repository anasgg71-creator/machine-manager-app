INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('ticket-images', 'ticket-images', true),
  ('ticket-documents', 'ticket-documents', true),
  ('ticket-videos', 'ticket-videos', true)
ON CONFLICT (id) DO NOTHING;
