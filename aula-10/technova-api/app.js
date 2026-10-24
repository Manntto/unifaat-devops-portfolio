const express = require('express');
const app = express();

const PORT = process.env.PORT || 3000;
const VERSION = process.env.APP_VERSION || '1.0.0';
const ENV = process.env.APP_ENV || 'production';

app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    servico: 'TechNova API - Aula 10',
    aluno: 'Matheus Mantovani',
    ra: '1120245',
    version: VERSION,
    env: ENV,
    status: 'online',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    version: VERSION,
    uptime: process.uptime()
  });
});

app.get('/version', (req, res) => {
  res.json({ version: VERSION, aula: '10' });
});

module.exports = app;

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`TechNova API v${VERSION} rodando na porta ${PORT}`);
  });
}
