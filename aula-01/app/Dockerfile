FROM node:20-alpine

WORKDIR /app

# Copia package.json antes do código-fonte para aproveitar cache de camadas
# A camada de npm install só é refeita quando as dependências mudam
COPY package*.json ./

RUN npm install --production

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
