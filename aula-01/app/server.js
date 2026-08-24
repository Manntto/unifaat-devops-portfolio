const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/', (req, res) => {
  res.json({
    servico: 'DevOps Portfolio API',
    aluno: 'Matheus Mantovani',
    ra: '1120245',
    aula: '01 - Fundamentos de Git e Docker',
    status: 'online',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    uptime: process.uptime(),
    version: '1.0.0'
  });
});

app.get('/about', (req, res) => {
  res.json({
    aluno: 'Matheus Mantovani',
    ra: '1120245',
    disciplina: 'DevOps — UniFAAT 2026-2',
    professor: 'Alexandre Tavares',
    descricao: 'API de portfólio desenvolvida na Aula 01 para demonstrar fundamentos de Git e Docker'
  });
});

app.listen(PORT, () => {
  console.log(`Portfolio API rodando na porta ${PORT}`);
});
