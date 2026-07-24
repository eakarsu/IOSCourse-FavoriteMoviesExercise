import assert from 'node:assert/strict';
import test from 'node:test';
import { runAiAttempt } from './attempts.mjs';
import { openRouter, RuntimeProviderError } from './provider.mjs';

const originalEnvironment = {
  key: process.env.OPENROUTER_API_KEY,
  model: process.env.OPENROUTER_MODEL,
  base: process.env.OPENROUTER_BASE_URL,
};
process.env.OPENROUTER_API_KEY = 'test-key';
process.env.OPENROUTER_MODEL = 'test/model';
process.env.OPENROUTER_BASE_URL = 'https://openrouter.ai/api/v1';

test.after(() => {
  for (const [name, value] of Object.entries({ OPENROUTER_API_KEY: originalEnvironment.key, OPENROUTER_MODEL: originalEnvironment.model, OPENROUTER_BASE_URL: originalEnvironment.base })) {
    if (value === undefined) delete process.env[name]; else process.env[name] = value;
  }
});

test('provider rejects malformed successful responses with a controlled error', async () => {
  const fetchImplementation = async () => ({ ok: true, status: 200, json: async () => ({ choices: [{}] }) });
  await assert.rejects(openRouter('deidentified workflow controls', { fetchImplementation }), error => {
    assert.equal(error instanceof RuntimeProviderError, true);
    assert.equal(error.code, 'OPENROUTER_RESPONSE_INVALID');
    assert.equal(error.status, 502);
    return true;
  });
});

test('unexpected provider failures finish the durable attempt as FAILED', async () => {
  let status = null;
  const statements = [];
  const queryImplementation = sql => {
    statements.push(sql);
    if (sql.startsWith('INSERT INTO runtime_ai_attempts')) { status = 'PENDING'; return '11111111-1111-4111-8111-111111111111'; }
    if (sql.startsWith('UPDATE runtime_ai_attempts SET status=\'FAILED\'')) { status = 'FAILED'; return '11111111-1111-4111-8111-111111111111'; }
    throw new Error('unexpected query');
  };
  await assert.rejects(runAiAttempt({
    user: { id: '22222222-2222-4222-8222-222222222222' },
    workflowSummary: 'deidentified workflow with privacy and human review controls',
    invoke: async () => { throw new TypeError('unexpected parser failure'); },
    queryImplementation,
  }), error => {
    assert.equal(error instanceof RuntimeProviderError, true);
    assert.equal(error.code, 'AI_INTERNAL_ERROR');
    return true;
  });
  assert.equal(status, 'FAILED');
  assert.equal(statements.some(statement => statement.includes("error_code='AI_INTERNAL_ERROR'")), true);
});

