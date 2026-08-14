-- Deno edge function: hard-delete the calling user via Auth Admin API.
-- Deploy: supabase functions deploy delete-account
-- Requires SUPABASE_SERVICE_ROLE_KEY (set automatically on hosted Supabase).

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Not authenticated' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const url = Deno.env.get('SUPABASE_URL') ?? ''
    const anon = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    const service = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

    const userClient = createClient(url, anon, {
      global: { headers: { Authorization: authHeader } },
    })
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser()
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Not authenticated' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const admin = createClient(url, service)

    // Clear FKs that block profile/auth deletion.
    const { data: mySuggestions } = await admin
      .from('suggestions')
      .select('id')
      .eq('suggested_by', user.id)
    const suggestionIds = (mySuggestions ?? []).map((s: { id: string }) => s.id)
    if (suggestionIds.length > 0) {
      await admin.from('races').update({ winner_id: null }).in('winner_id', suggestionIds)
      await admin
        .from('rooms')
        .update({ winner_suggestion_id: null })
        .in('winner_suggestion_id', suggestionIds)
    }
    await admin.from('rooms').delete().eq('host_id', user.id)
    await admin.from('suggestions').delete().eq('suggested_by', user.id)
    await admin
      .from('receipts')
      .update({ uploaded_by: null })
      .eq('uploaded_by', user.id)

    const { error: deleteError } = await admin.auth.admin.deleteUser(user.id)
    if (deleteError) throw deleteError

    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    return new Response(JSON.stringify({ error: message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
