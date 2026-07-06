/**
 * Create or update a PR comment identified by an HTML marker (hidden in rendered view).
 * Markers prevent comment spam on repeated workflow runs.
 */

const MARKER_PREFIX = '<!-- workflow-bot:';

function markerTag(marker) {
  return `${MARKER_PREFIX}${marker} -->`;
}

async function listBotComments(github, context, pr) {
  const { data: comments } = await github.rest.issues.listComments({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: pr,
    per_page: 100,
  });

  return comments.filter((comment) => comment.user?.type === 'Bot');
}

async function findMarkedComment(github, context, pr, marker) {
  const tag = markerTag(marker);
  const botComments = await listBotComments(github, context, pr);
  return botComments.find((comment) => comment.body?.includes(tag)) ?? null;
}

function resolvePullNumber(context, explicitPr) {
  if (explicitPr) {
    return Number(explicitPr);
  }

  if (context.payload.pull_request?.number) {
    return context.payload.pull_request.number;
  }

  if (context.payload.issue?.number) {
    return context.payload.issue.number;
  }

  throw new Error('Could not resolve pull request number for PR comment.');
}

async function upsertPrComment(github, context, core, { marker, body, prNumber }) {
  const pr = resolvePullNumber(context, prNumber);
  const tag = markerTag(marker);
  const fullBody = `${tag}\n${body}`;
  const existing = await findMarkedComment(github, context, pr, marker);

  if (existing) {
    await github.rest.issues.updateComment({
      owner: context.repo.owner,
      repo: context.repo.repo,
      comment_id: existing.id,
      body: fullBody,
    });
    core.info(`Updated PR #${pr} comment (${marker})`);
    return existing.id;
  }

  const { data: created } = await github.rest.issues.createComment({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: pr,
    body: fullBody,
  });
  core.info(`Created PR #${pr} comment (${marker})`);
  return created.id;
}

async function deleteMarkedComment(github, context, core, { marker, prNumber }) {
  const pr = resolvePullNumber(context, prNumber);
  const existing = await findMarkedComment(github, context, pr, marker);

  if (!existing) {
    return;
  }

  await github.rest.issues.deleteComment({
    owner: context.repo.owner,
    repo: context.repo.repo,
    comment_id: existing.id,
  });
  core.info(`Deleted PR #${pr} comment (${marker})`);
}

module.exports = {
  upsertPrComment,
  deleteMarkedComment,
  findMarkedComment,
  markerTag,
};
