# This Dockerfile is specifically tailored for building the app for AWS Marketplace deployment.

# Step 1: Build the application
FROM public.ecr.aws/docker/library/node:20-alpine AS builder

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
RUN npm run build

# Step 2: Set up the production environment
FROM public.ecr.aws/nginx/nginx:stable-alpine

# Create non-root user for nginx
RUN addgroup --system --gid 1001 app && \
    adduser --system --uid 1001 app && \
    chown -R app:app /usr/share/nginx/html /var/cache/nginx /var/log/nginx /run

COPY --from=builder --chown=app:app /app/dist /usr/share/nginx/html
COPY --chown=app:app nginx.conf /etc/nginx/conf.d/default.conf

USER app

# non-root users can bind to ports above 1024
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
