const request = require('supertest');
const app = require('../app');

describe('GET /', () => {
  test('retorna status 200', async () => {
    const res = await request(app).get('/');
    expect(res.status).toBe(200);
  });
  test('retorna campo servico correto', async () => {
    const res = await request(app).get('/');
    expect(res.body.servico).toBe('TechNova API - Aula 10');
  });
  test('retorna ra correto', async () => {
    const res = await request(app).get('/');
    expect(res.body.ra).toBe('1120245');
  });
});

describe('GET /health', () => {
  test('retorna status ok', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
  test('retorna uptime', async () => {
    const res = await request(app).get('/health');
    expect(res.body).toHaveProperty('uptime');
  });
});

describe('GET /version', () => {
  test('retorna aula 10', async () => {
    const res = await request(app).get('/version');
    expect(res.status).toBe(200);
    expect(res.body.aula).toBe('10');
  });
});
