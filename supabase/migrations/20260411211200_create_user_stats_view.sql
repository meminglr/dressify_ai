-- Create user_stats view
-- Requirements: 3.1, 3.2

-- View to calculate user statistics from media table
-- Returns aggregated counts of different media types per user
-- Uses SECURITY INVOKER to respect RLS policies of the querying user
CREATE OR REPLACE VIEW user_stats
WITH (security_invoker = true)
AS
SELECT 
  user_id,
  COUNT(*) FILTER (WHERE type = 'AI_CREATION') AS ai_looks_count,
  COUNT(*) FILTER (WHERE type = 'UPLOAD') AS uploads_count,
  COUNT(*) FILTER (WHERE type = 'MODEL') AS models_count
FROM media
GROUP BY user_id;

-- Add comment to view
COMMENT ON VIEW user_stats IS 'Aggregated user statistics showing counts of AI creations, uploads, and models per user';
