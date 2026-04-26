# Use an official Maven image as the base image
FROM maven:3.8.8-eclipse-temurin-21-alpine AS build

# Set the working directory in the container
WORKDIR /app

# Copy the pom.xml and the project files to the container
COPY pom.xml .
COPY src ./src

# Build the application using Maven
RUN mvn clean install

# Set the command to run the application
CMD ["mvn", "exec:java", "-Dexec.mainClass=com.package.App"]