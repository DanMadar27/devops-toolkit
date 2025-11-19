# Use the official Node.js 14 image as a base image
FROM node:20-alpine

# Install curl for healthcheck
RUN apk --no-cache add curl

# Create a non-root user
RUN addgroup --system --gid 1001 app && \
    adduser --system --uid 1001 app

# Set the working directory in the container
WORKDIR /app

# Change ownership of the workdir to app user
RUN chown app:app /app

# Switch to the app user before copying files
USER app

# Copy package.json and package-lock.json to the working directory
COPY --chown=app:app package*.json ./

# Install dependencies
RUN npm ci

# Copy the rest of the application code
COPY --chown=app:app . .

# Expose port 4000
EXPOSE 4000

# Command to run the application
CMD ["npm", "start"]
