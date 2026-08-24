FROM node:20-alpine

WORKDIR /app

# Copia package.json antes do código para aproveitar cache de camadas
COPY package*.json ./

RUN npm install --production

COPY . .

EXPOSE 3000

CMD ["node", "app.js"]
