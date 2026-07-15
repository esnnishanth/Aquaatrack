const express = require('express');
const sharp = require('sharp');

const router = express.Router();

const GROQ_API_URL = 'https://api.groq.com/openai/v1/chat/completions';
const MODELS = ['meta-llama/llama-4-scout-17b-16e-instruct', 'qwen/qwen3.6-27b'];
const MODEL_TIMEOUT = 20000;

const SYSTEM_PROMPT = `Extract handwritten bore work bill data into JSON.

Schema:
{
  "bore_number": string|null,
  "date": string|null,
  "agent_name": string|null,
  "feet_entries": [{ "length": number, "rate": number, "amount": number|null }],
  "feet_total_amount": number|null,
  "pipe_entries": [{ "size": number, "length": number, "price": number, "amount": number|null }],
  "pipe_total_amount": number|null,
  "steel": { "applicable": boolean, "feet": number|null, "price_per_feet": number|null, "welding_charge": number|null, "amount": number|null } | null,
  "total_bill": number|null,
  "initial_payment": number|null,
  "unclear_fields": string[]
}

Rules:
- Extract ONLY handwritten values. Never guess or calculate totals.
- If blank/illegible: set to null, add field name to unclear_fields.
- bore_number: handwritten ID (e.g. B021). agent_name: keep original case.
- feet_entries: length(ft), rate(Rs/ft), amount(Rs) from Bore Feet Entries.
- pipe_entries: size(inch), length(ft), price(Rs/ft), amount(Rs) from PVC Pipe Entries.
- steel: if N/A ticked, applicable=false. Else extract feet, price_per_feet, welding_charge, amount.
- total_bill: grand total. initial_payment: amount received.`;

async function prepareImage(base64Str) {
  const buf = Buffer.from(base64Str, 'base64');
  const processed = await sharp(buf)
    .resize(800, 800, { fit: 'inside', withoutEnlargement: true })
    .jpeg({ quality: 80 })
    .toBuffer();
  return `data:image/jpeg;base64,${processed.toString('base64')}`;
}

async function callModel(model, dataUrl, signal) {
  const resp = await fetch(GROQ_API_URL, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.GROQ_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        {
          role: 'user',
          content: [
            { type: 'text', text: 'Extract data from this bore work bill.' },
            { type: 'image_url', image_url: { url: dataUrl } },
          ],
        },
      ],
      response_format: { type: 'json_object' },
      max_tokens: 600,
      temperature: 0.1,
    }),
    signal,
  });

  if (!resp.ok) {
    const errBody = await resp.text();
    throw new Error(`Groq ${resp.status}: ${errBody.slice(0, 300)}`);
  }

  const json = await resp.json();
  const content = json.choices?.[0]?.message?.content?.trim() || '{}';
  try {
    return JSON.parse(content);
  } catch {
    throw new Error(`Invalid JSON: ${content.slice(0, 500)}`);
  }
}

function callWithTimeout(model, dataUrl, timeoutMs) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  const promise = callModel(model, dataUrl, controller.signal)
    .finally(() => clearTimeout(timer));
  promise._cancel = () => { clearTimeout(timer); controller.abort(); };
  return promise;
}

async function tryModelsParallel(dataUrl) {
  const controllers = MODELS.map(() => new AbortController());
  const timers = MODELS.map((_, i) => setTimeout(() => controllers[i].abort(), MODEL_TIMEOUT));

  const promises = MODELS.map((model, i) =>
    callModel(model, dataUrl, controllers[i].signal)
      .finally(() => clearTimeout(timers[i]))
  );

  let settled = false;

  const results = await Promise.allSettled(
    promises.map((p, i) =>
      p.then(value => {
        settled = true;
        controllers.forEach((c, j) => { if (j !== i) c.abort(); });
        return value;
      })
    )
  );

  for (const r of results) {
    if (r.status === 'fulfilled') return r.value;
  }

  throw new Error(results.map(r => r.reason?.message).join('; '));
}

router.get('/ping', (req, res) => res.json({ pong: true }));

router.post('/ocr-bore-bill', async (req, res) => {
  try {
    const { image_base64, media_type } = req.body;
    if (!image_base64) {
      return res.status(400).json({ error: 'image_base64 is required' });
    }

    let dataUrl;
    try {
      dataUrl = await prepareImage(image_base64);
    } catch (imgErr) {
      dataUrl = `data:${media_type || 'image/jpeg'};base64,${image_base64}`;
    }

    const result = await tryModelsParallel(dataUrl);
    res.json(result);
  } catch (err) {
    console.error('OCR error:', err);
    res.status(502).json({ error: 'OCR extraction failed', detail: err.message });
  }
});

module.exports = router;
