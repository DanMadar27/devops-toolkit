# Use an official PHP runtime as a parent image
FROM php:7.1-apache

WORKDIR /app/installations

# Set the working directory in the container to /var/www/html
WORKDIR /var/www/html

# Install necessary PHP extensions and tools
RUN apt-get update && apt-get install -y \
    zlib1g-dev \
    libzip-dev \
    libpng-dev \
    libgmp-dev \
    unzip 

# Install necessary PHP extensions and tools
RUN docker-php-ext-install pdo pdo_mysql
RUN docker-php-ext-enable pdo
RUN docker-php-ext-enable pdo_mysql
RUN docker-php-ext-install zip
RUN docker-php-ext-enable zip
RUN docker-php-ext-install gd
RUN docker-php-ext-enable gd

ENV COMPOSER_ALLOW_SUPERUSER=1

# Copy the Composer PHAR file and install Composer
COPY composer.phar /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer

# Copy the current directory contents into the container at /var/www/html
COPY . /var/www/html

# Enable permissions on app directory only read
RUN chmod -R 755

# Install project dependencies using Composer
RUN composer update 

# Expose port 80
EXPOSE 80

# Run Apache in the foreground
CMD ["apache2-foreground"]