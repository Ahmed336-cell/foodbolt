const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

const htmlHeaders = new Headers(corsHeaders)
htmlHeaders.set('Content-Type', 'text/html; charset=utf-8')
htmlHeaders.set('Cache-Control', 'no-store')

function escapeHtml(value: string) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;')
}

Deno.serve((req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const url = new URL(req.url)
  const token =
    url.searchParams.get('code') ??
    url.pathname.split('/').filter(Boolean).at(-1) ??
    ''
  const safeToken = escapeHtml(decodeURIComponent(token.trim()))
  const appUrl = `foodrush://join/${encodeURIComponent(safeToken)}`

  return new Response(
    `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Join FoodRush</title>
  <style>
    body { margin: 0; font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; color: #141830; background: #fff8f0; }
    main { min-height: 100vh; display: grid; place-items: center; padding: 24px; box-sizing: border-box; }
    .card { width: min(100%, 460px); padding: 28px; border-radius: 24px; background: white; box-shadow: 0 18px 60px rgba(20, 24, 48, 0.12); text-align: center; }
    h1 { margin: 0 0 8px; font-size: 28px; }
    p { margin: 8px 0; color: #666; line-height: 1.5; }
    .code { margin: 20px 0; padding: 14px 18px; border-radius: 16px; background: #fff3e6; color: #e85d04; font-size: 28px; font-weight: 800; letter-spacing: 0.12em; }
    .actions { display: grid; gap: 10px; margin-top: 18px; }
    a, button { display: block; width: 100%; padding: 14px 16px; border-radius: 14px; border: 0; box-sizing: border-box; font: inherit; font-weight: 800; text-decoration: none; cursor: pointer; }
    .primary { background: #e85d04; color: white; }
    .secondary { background: #fff3e6; color: #e85d04; }
  </style>
</head>
<body>
  <main>
    <section class="card">
      <h1>Join FoodRush</h1>
      <p>Open the app to join this room.</p>
      <div class="code">${safeToken || 'NO CODE'}</div>
      <div class="actions">
        <a class="primary" href="${appUrl}">Open FoodRush</a>
        <button class="secondary" id="copy-code" type="button">Copy room code</button>
      </div>
    </section>
  </main>
  <script>
    const token = ${JSON.stringify(safeToken)};
    const appUrl = ${JSON.stringify(appUrl)};
    document.getElementById('copy-code').addEventListener('click', async () => {
      await navigator.clipboard.writeText(token);
      document.getElementById('copy-code').textContent = 'Copied';
    });
    if (token) setTimeout(() => { window.location.href = appUrl; }, 400);
  </script>
</body>
</html>`,
    { status: 200, headers: htmlHeaders },
  )
})
