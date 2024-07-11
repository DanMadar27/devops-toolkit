# Step 1: Build the application
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

# Copy project files and build (from your branch)
COPY . .
RUN npm run build

# Step 2: Set up the production environment
FROM nginx:stable-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
