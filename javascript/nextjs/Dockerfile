FROM node:20-alpine

# Install curl for healthcheck
RUN apk --no-cache add curl

ENV API_URL=/api

# Create a non-root user
RUN addgroup --system --gid 1001 app && \
    adduser --system --uid 1001 app

WORKDIR /app

# Change ownership of the workdir to app user
RUN chown app:app /app

# Switch to the app user before copying files
USER app

COPY --chown=app:app package*.json ./

RUN npm ci

COPY --chown=app:app . .

RUN npx next telemetry disable

RUN npm run build

EXPOSE 3000

CMD [ "npm", "run", "start" ]