import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

interface GenerateOutfitRequest {
  style_tag?: string;
  prompt?: string;
}

interface GenerateOutfitResponse {
  success: boolean;
  media_id?: string;
  image_url?: string;
  error?: string;
}

Deno.serve(async (req: Request) => {
  // CORS headers
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };

  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // Only allow POST requests
  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ success: false, error: 'Method not allowed' }),
      { 
        status: 405, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );
  }

  try {
    // Get JWT token from Authorization header
    const authHeader = req.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing or invalid authorization header' }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    const token = authHeader.replace('Bearer ', '');

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    
    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // Verify JWT token and get user
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    
    if (authError || !user) {
      console.error('Auth error:', authError);
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid or expired token' }),
        { 
          status: 401, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    // Parse request body
    const requestBody: GenerateOutfitRequest = await req.json();
    const { style_tag, prompt } = requestBody;

    console.log(`Generating outfit for user ${user.id} with style: ${style_tag}, prompt: ${prompt}`);

    // TODO: Replace with actual AI generation logic
    // For now, we'll use a placeholder image generation
    const generatedImageData = await generatePlaceholderOutfit(style_tag, prompt);
    
    // Upload generated image to gallery bucket
    const fileName = `${user.id}/${crypto.randomUUID()}.png`;
    
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('gallery')
      .upload(fileName, generatedImageData, {
        contentType: 'image/png',
        upsert: false,
      });

    if (uploadError) {
      console.error('Upload error:', uploadError);
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to upload generated image' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    // Get public URL for the uploaded image
    const { data: urlData } = supabase.storage
      .from('gallery')
      .getPublicUrl(fileName);

    const imageUrl = urlData.publicUrl;

    // Insert record into media table
    const { data: mediaData, error: mediaError } = await supabase
      .from('media')
      .insert({
        user_id: user.id,
        image_url: imageUrl,
        type: 'AI_CREATION',
        style_tag: style_tag || null,
      })
      .select()
      .single();

    if (mediaError) {
      console.error('Media insert error:', mediaError);
      
      // Clean up uploaded file if database insert fails
      await supabase.storage.from('gallery').remove([fileName]);
      
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to save media record' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      );
    }

    const response: GenerateOutfitResponse = {
      success: true,
      media_id: mediaData.id,
      image_url: imageUrl,
    };

    return new Response(
      JSON.stringify(response),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );

  } catch (error) {
    console.error('Unexpected error:', error);
    
    return new Response(
      JSON.stringify({ 
        success: false, 
        error: 'Internal server error' 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );
  }
});

/**
 * Placeholder AI outfit generation function
 * TODO: Replace with actual AI service integration (OpenAI DALL-E, Midjourney, etc.)
 */
async function generatePlaceholderOutfit(styleTag?: string, prompt?: string): Promise<Uint8Array> {
  // For now, generate a simple colored rectangle as placeholder
  // In a real implementation, this would call an AI service
  
  const canvas = new OffscreenCanvas(512, 512);
  const ctx = canvas.getContext('2d')!;
  
  // Generate a random color based on style_tag or prompt
  const colors = {
    'casual': '#4A90E2',
    'formal': '#2C3E50',
    'sporty': '#E74C3C',
    'elegant': '#8E44AD',
    'vintage': '#D35400',
    'modern': '#1ABC9C',
  };
  
  const color = colors[styleTag as keyof typeof colors] || '#95A5A6';
  
  // Fill background
  ctx.fillStyle = color;
  ctx.fillRect(0, 0, 512, 512);
  
  // Add some text
  ctx.fillStyle = 'white';
  ctx.font = '24px Arial';
  ctx.textAlign = 'center';
  ctx.fillText('AI Generated Outfit', 256, 200);
  
  if (styleTag) {
    ctx.font = '18px Arial';
    ctx.fillText(`Style: ${styleTag}`, 256, 250);
  }
  
  if (prompt) {
    ctx.font = '14px Arial';
    const words = prompt.split(' ');
    const lines = [];
    let currentLine = '';
    
    for (const word of words) {
      const testLine = currentLine + word + ' ';
      if (testLine.length > 30) {
        lines.push(currentLine.trim());
        currentLine = word + ' ';
      } else {
        currentLine = testLine;
      }
    }
    lines.push(currentLine.trim());
    
    lines.forEach((line, index) => {
      ctx.fillText(line, 256, 300 + (index * 20));
    });
  }
  
  // Add timestamp
  ctx.font = '12px Arial';
  ctx.fillText(new Date().toISOString(), 256, 450);
  
  // Convert to PNG blob
  const blob = await canvas.convertToBlob({ type: 'image/png' });
  const arrayBuffer = await blob.arrayBuffer();
  
  return new Uint8Array(arrayBuffer);
}