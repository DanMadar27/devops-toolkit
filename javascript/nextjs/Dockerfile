FROM node:20-alpine

# Install curl for healthcheck
RUN apk --no-cache add curl

ENV API_URL=/api

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npx next telemetry disable

RUN npm run build

EXPOSE 3000

CMD [ "npm", "run", "start" ]