-- Realtime receipt rows must include storage_path so every member can
-- resolve a signed URL and see the photo.

alter table public.receipts replica identity full;
