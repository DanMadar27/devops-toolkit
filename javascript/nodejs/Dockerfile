# Use the official Node.js 14 image as a base image
FROM node:20-alpine

# Set the working directory in the container
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy the rest of the application code
COPY . .

# Expose port 4000
EXPOSE 4000

# Command to run the application
CMD ["npm", "start"]
