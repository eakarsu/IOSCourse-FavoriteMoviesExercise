import { literal, query } from './db.mjs';
import { RuntimeProviderError } from './provider.mjs';

const feature = 'movie-library-readiness';

export async function runAiAttempt({ user, workflowSummary, invoke, queryImplementation = query }) {
  const input = JSON.stringify({ workflowSummary });
  const requestedModel = String(process.env.OPENROUTER_MODEL || '').trim();
  const attemptId = queryImplementation(`INSERT INTO runtime_ai_attempts(user_id,feature,input,requested_model,status)
    VALUES(${literal(user.id)}::uuid,${literal(feature)},${literal(input)}::jsonb,${literal(requestedModel)},'PENDING') RETURNING id`, { rows: true });
  if (!attemptId) throw Object.assign(new Error('AI attempt could not be initialized'), { status: 500, code: 'AI_ATTEMPT_INIT_FAILED' });
  try {
    const evidence = await invoke(workflowSummary);
    const saved = queryImplementation(`WITH saved AS (
      INSERT INTO runtime_ai_results(user_id,feature,input,provider_request_id,provider_model,result_text,provider_receipt)
      VALUES(${literal(user.id)}::uuid,${literal(feature)},${literal(input)}::jsonb,${literal(evidence.receipt.requestId)},${literal(evidence.receipt.model)},${literal(evidence.content)},${literal(JSON.stringify(evidence.receipt))}::jsonb)
      RETURNING id
    )
    UPDATE runtime_ai_attempts AS attempt SET status='SUCCEEDED',provider_request_id=${literal(evidence.receipt.requestId)},
      provider_model=${literal(evidence.receipt.model)},result_id=saved.id,completed_at=NOW()
    FROM saved WHERE attempt.id=${literal(attemptId)}::uuid AND attempt.status='PENDING'
    RETURNING attempt.result_id`, { rows: true });
    if (!saved) throw Object.assign(new Error('AI success evidence could not be finalized'), { status: 500, code: 'AI_EVIDENCE_FINALIZE_FAILED' });
    return { analysisId: saved, result: evidence.content, model: evidence.receipt.model, providerReceipt: evidence.receipt, movieDataShared: false };
  } catch (error) {
    const code = error instanceof RuntimeProviderError ? error.code : 'AI_INTERNAL_ERROR';
    const finalized = queryImplementation(`UPDATE runtime_ai_attempts SET status='FAILED',error_code=${literal(code)},completed_at=NOW()
      WHERE id=${literal(attemptId)}::uuid AND status='PENDING' RETURNING id`, { rows: true });
    if (!finalized) throw Object.assign(new Error('AI failure evidence could not be finalized'), { status: 500, code: 'AI_EVIDENCE_FINALIZE_FAILED' });
    if (error instanceof RuntimeProviderError) throw error;
    throw new RuntimeProviderError('AI_INTERNAL_ERROR', 'AI processing failed safely', 502, error);
  }
}
