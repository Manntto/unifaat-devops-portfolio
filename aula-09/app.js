const express = require('express');
const app = express();

const PORT = process.env.PORT || 3000;
const DB_HOST = process.env.DB_HOST || 'localhost';
const DB_PORT = process.env.DB_PORT || 5432;
const DB_NAME = process.env.DB_NAME || 'technova';

app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    servico: 'TechNova API - Aula 09',
    aluno: 'Matheus Mantovani',
    ra: '1120245',
    status: 'online',
    banco: `${DB_HOST}:${DB_PORT}/${DB_NAME}`,
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    uptime: process.uptime()
  });
});

app.get('/version', (req, res) => {
  res.json({ version: '1.0.0', aula: '09' });
});

module.exports = app;

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`TechNova API rodando na porta ${PORT}`);
  });
}


});
