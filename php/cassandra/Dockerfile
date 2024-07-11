# Use an official PHP runtime as a parent image
FROM php:7.1-apache

WORKDIR /app/installations

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y libgmp-dev git zlib1g-dev libssl-dev libkrb5-dev make cmake

# Install libuv
RUN apt-get install -y automake libtool curl
RUN curl -sSL https://github.com/libuv/libuv/archive/v1.8.0.tar.gz | tar zxfv - -C /usr/local/src
WORKDIR /usr/local/src/libuv-1.8.0
RUN chmod +x autogen.sh
RUN sh autogen.sh
RUN ./configure
RUN make
RUN make install
WORKDIR /app/installations
RUN rm -rf /usr/local/src/libuv-1.8.0
RUN ldconfig

# Download and install the DataStax C/C++ driver
RUN curl -L https://github.com/datastax/cpp-driver/archive/refs/tags/2.15.0.tar.gz | tar xz
WORKDIR /app/installations/cpp-driver-2.15.0
RUN cmake . && make && make install

# Clean up the DataStax C/C++ driver build files
WORKDIR /app/installations
RUN rm -rf cpp-driver-2.15.0

# Install the PHP Cassandra extension via PECL
RUN pecl install cassandra && docker-php-ext-enable cassandra

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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

# Enable permissions on app directory
RUN chmod -R 755 /var/www/html

# Install project dependencies using Composer
RUN composer update 

# Expose port 80
EXPOSE 80

# Run Apache in the foreground
CMD ["apache2-foreground"]