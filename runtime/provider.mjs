export class RuntimeProviderError extends Error {
  constructor(code, message, status = 502, cause) {
    super(message, cause ? { cause } : undefined);
    this.name = 'RuntimeProviderError';
    this.code = code;
    this.status = status;
  }
}

export async function openRouter(workflowSummary, { fetchImplementation = fetch } = {}) {
  const baseUrl = String(process.env.OPENROUTER_BASE_URL || '').replace(/\/+$/, '');
  const model = String(process.env.OPENROUTER_MODEL || '').trim();
  const apiKey = String(process.env.OPENROUTER_API_KEY || '').trim();
  if (baseUrl !== 'https://openrouter.ai/api/v1' || !model || !apiKey) {
    throw new RuntimeProviderError('OPENROUTER_CONFIGURATION_INVALID', 'Exact OpenRouter configuration is required', 503);
  }
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 45_000);
  let response;
  try {
    response = await fetchImplementation(`${baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': 'http://localhost',
        'X-Title': 'Favorite Movies Runtime Verification',
      },
      body: JSON.stringify({
        model,
        temperature: 0.1,
        messages: [
          {
            role: 'system',
            content: 'You are an operations-readiness assistant for an offline favorite-movies learning app. Review only the deidentified administrative workflow. Never request movie titles, reviews, user preferences, or device data. Return concise privacy, persistence, accessibility, and human-review checks.',
          },
          { role: 'user', content: workflowSummary },
        ],
      }),
      signal: controller.signal,
    });
  } catch (error) {
    throw new RuntimeProviderError('OPENROUTER_REQUEST_FAILED', 'OpenRouter request failed safely', 502, error);
  } finally {
    clearTimeout(timeout);
  }
  let payload;
  try {
    payload = await response.json();
  } catch (error) {
    throw new RuntimeProviderError('OPENROUTER_RESPONSE_INVALID', 'OpenRouter response was not valid JSON', 502, error);
  }
  if (!response.ok) throw new RuntimeProviderError('OPENROUTER_HTTP_ERROR', `OpenRouter returned HTTP ${response.status}`);
  const requestId = typeof payload?.id === 'string' ? payload.id.trim() : '';
  const providerModel = typeof payload?.model === 'string' ? payload.model.trim() : model;
  const content = typeof payload?.choices?.[0]?.message?.content === 'string' ? payload.choices[0].message.content.trim() : '';
  if (!requestId || !providerModel || content.length < 40) {
    throw new RuntimeProviderError('OPENROUTER_RESPONSE_INVALID', 'OpenRouter returned incomplete evidence');
  }
  return { content, receipt: { requestId, model: providerModel, provider: 'openrouter' } };
}

