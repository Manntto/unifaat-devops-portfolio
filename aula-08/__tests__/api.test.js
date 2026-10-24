const request = require('supertest');
const app = require('../app');

describe('GET /', () => {
  test('retorna status 200', async () => {
    const res = await request(app).get('/');
    expect(res.status).toBe(200);
  });

  test('retorna campo servico correto', async () => {
    const res = await request(app).get('/');
    expect(res.body.servico).toBe('TechNova API - Aula 08');
  });

  test('retorna ra do aluno', async () => {
    const res = await request(app).get('/');
    expect(res.body.ra).toBe('1120245');
  });
});

describe('GET /health', () => {
  test('retorna status healthy', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('healthy');
  });

  test('retorna campo uptime', async () => {
    const res = await request(app).get('/health');
    expect(res.body).toHaveProperty('uptime');
  });
});

describe('GET /version', () => {
  test('retorna versão da API', async () => {
    const res = await request(app).get('/version');
    expect(res.status).toBe(200);
    expect(res.body.version).toBe('1.0.0');
    expect(res.body.aula).toBe('08');
  });
});
