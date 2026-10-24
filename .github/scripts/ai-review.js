#!/usr/bin/env node
/**
 * AI Review — Analisador estático de PRs
 * Detecta padrões problemáticos no diff de um PR e posta comentário no GitHub
 *
 * Uso: node .github/scripts/ai-review.js
 * Env vars: GITHUB_TOKEN, GITHUB_REPOSITORY, PR_NUMBER, PR_DIFF
 */

const https = require('https');

// ── Padrões de análise ────────────────────────────────────────────────────────
const PATTERNS = [
  {
    id: 'SECRET_HARDCODED',
    severity: 'CRITICAL',
    description: 'Possível secret ou credencial hardcoded no código',
    regex: /(password|passwd|pwd|secret|api_key|apikey|token|auth)\s*[:=]\s*['"][^'"]{4,}['"]/gi,
    suggestion: 'Use variáveis de ambiente ou GitHub Secrets. Nunca commite credenciais.'
  },
  {
    id: 'EVAL_USAGE',
    severity: 'CRITICAL',
    description: 'Uso de eval() detectado — risco de execução de código arbitrário',
    regex: /\beval\s*\(/g,
    suggestion: 'Evite eval(). Use JSON.parse() para dados JSON ou alternativas seguras.'
  },
  {
    id: 'SQL_INJECTION',
    severity: 'CRITICAL',
    description: 'Possível concatenação direta em query SQL — risco de SQL injection',
    regex: /(SELECT|INSERT|UPDATE|DELETE|DROP).*\+.*req\.(body|params|query)/gi,
    suggestion: 'Use queries parametrizadas (prepared statements) ou um ORM.'
  },
  {
    id: 'CONSOLE_LOG',
    severity: 'WARNING',
    description: 'console.log() em código de produção pode vazar dados sensíveis',
    regex: /console\.(log|debug|info)\s*\(/g,
    suggestion: 'Use um logger estruturado (ex: winston, pino) com níveis configuráveis.'
  },
  {
    id: 'EMPTY_CATCH',
    severity: 'WARNING',
    description: 'Bloco catch vazio silencia erros — dificulta debugging',
    regex: /catch\s*\([^)]*\)\s*\{\s*\}/g,
    suggestion: 'Adicione ao menos um log ou re-throw do erro no bloco catch.'
  },
  {
    id: 'TODO_FIXME',
    severity: 'INFO',
    description: 'TODO ou FIXME encontrado — pendência não resolvida',
    regex: /\/\/\s*(TODO|FIXME|HACK|XXX)[:.\s]/gi,
    suggestion: 'Resolva o TODO/FIXME ou crie uma issue para rastreamento.'
  },
  {
    id: 'WEAK_CRYPTO',
    severity: 'CRITICAL',
    description: 'Algoritmo criptográfico fraco detectado (MD5 ou SHA1)',
    regex: /\b(md5|sha1)\b/gi,
    suggestion: 'Use SHA-256 ou superior. MD5 e SHA1 são considerados inseguros.'
  },
  {
    id: 'HTTP_NOT_HTTPS',
    severity: 'WARNING',
    description: 'URL HTTP encontrada — dados trafegam sem criptografia',
    regex: /http:\/\/(?!localhost|127\.0\.0\.1|0\.0\.0\.0)/g,
    suggestion: 'Use HTTPS em produção para criptografar os dados em trânsito.'
  }
];

// ── Análise do diff ───────────────────────────────────────────────────────────
function analyzeDiff(diff) {
  const findings = [];

  // Analisa apenas linhas adicionadas (começam com +, excluindo +++)
  const addedLines = diff
    .split('\n')
    .filter(line => line.startsWith('+') && !line.startsWith('+++'));

  for (const pattern of PATTERNS) {
    for (const line of addedLines) {
      if (pattern.regex.test(line)) {
        findings.push({
          ...pattern,
          line: line.substring(1).trim()  // Remove o '+' inicial
        });
        pattern.regex.lastIndex = 0;      // Reset para regex com flag 'g'
      }
    }
  }

  return findings;
}

// ── Formata comentário ────────────────────────────────────────────────────────
function formatComment(findings) {
  if (findings.length === 0) {
    return [
      '## 🤖 AI Review — Resultado',
      '',
      '✅ **Nenhum problema encontrado.** O código passou na análise automatizada.',
      '',
      '_Análise realizada por: AI Review (pattern matching estático)_'
    ].join('\n');
  }

  const critical = findings.filter(f => f.severity === 'CRITICAL');
  const warnings = findings.filter(f => f.severity === 'WARNING');
  const infos    = findings.filter(f => f.severity === 'INFO');

  const icon = critical.length > 0 ? '🔴' : warnings.length > 0 ? '🟡' : '🟢';
  const status = critical.length > 0
    ? `**${critical.length} problema(s) CRITICAL encontrado(s) — merge bloqueado.**`
    : '**Nenhum problema crítico — merge permitido.**';

  const rows = findings.map(f => {
    const sev = f.severity === 'CRITICAL' ? '🔴 CRITICAL'
              : f.severity === 'WARNING'  ? '🟡 WARNING'
              : '🔵 INFO';
    const line = f.line.length > 60 ? f.line.substring(0, 57) + '...' : f.line;
    return `| ${sev} | ${f.description} | \`${line}\` | ${f.suggestion} |`;
  });

  return [
    `## ${icon} AI Review — Resultado`,
    '',
    status,
    '',
    `| Severidade | Problema | Trecho | Sugestão |`,
    `|------------|----------|--------|----------|`,
    ...rows,
    '',
    `**Resumo:** 🔴 ${critical.length} CRITICAL | 🟡 ${warnings.length} WARNING | 🔵 ${infos.length} INFO`,
    '',
    '_Análise realizada por: AI Review (pattern matching estático) — revise manualmente antes de mergear._'
  ].join('\n');
}

// ── Posta comentário no PR ────────────────────────────────────────────────────
function postComment(comment, callback) {
  const token = process.env.GITHUB_TOKEN;
  const repo  = process.env.GITHUB_REPOSITORY;
  const prNum = process.env.PR_NUMBER;

  if (!token || !repo || !prNum) {
    console.log('Variáveis de ambiente ausentes — imprimindo comentário:');
    console.log(comment);
    return callback(null);
  }

  const body = JSON.stringify({ body: comment });
  const options = {
    hostname: 'api.github.com',
    path: `/repos/${repo}/issues/${prNum}/comments`,
    method: 'POST',
    headers: {
      'Authorization': `token ${token}`,
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(body),
      'User-Agent': 'ai-review-bot'
    }
  };

  const req = https.request(options, res => {
    let data = '';
    res.on('data', chunk => { data += chunk; });
    res.on('end', () => {
      if (res.statusCode === 201) {
        console.log('✅ Comentário postado no PR.');
        callback(null);
      } else {
        callback(new Error(`GitHub API retornou ${res.statusCode}: ${data}`));
      }
    });
  });
  req.on('error', callback);
  req.write(body);
  req.end();
}

// ── Main ──────────────────────────────────────────────────────────────────────
const diff = process.env.PR_DIFF || '';
const findings = analyzeDiff(diff);
const comment  = formatComment(findings);
const hasCritical = findings.some(f => f.severity === 'CRITICAL');

console.log('─── AI Review Output ───────────────────────────────');
console.log(comment);
console.log('────────────────────────────────────────────────────');
console.log(`Achados: ${findings.length} | CRITICAL: ${findings.filter(f=>f.severity==='CRITICAL').length}`);

postComment(comment, (err) => {
  if (err) console.error('Erro ao postar comentário:', err.message);
  // Quality gate: exit 1 se CRITICAL
  process.exit(hasCritical ? 1 : 0);
});
