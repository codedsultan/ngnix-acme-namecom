FROM nginx:alpine

# Install required packages
RUN apk add --no-cache bash curl

# Ensure www-data user and group exist only if missing
RUN getent group www-data || addgroup -g 33 -S www-data && \
    getent passwd www-data || adduser -u 33 -D -S -G www-data www-data

# Ensure required directories exist before changing ownership
RUN mkdir -p /var/cache/nginx /var/run /var/www/errors /var/www/laravel/public /var/www/laravel/storage /var/www/nodejs/static /var/log/nginx && \
    chown -R www-data:www-data /var/www/errors /var/www/laravel/public /var/www/laravel/storage /var/www/nodejs/static /var/log/nginx
    

RUN mkdir -p /var/run/nginx && chown -R www-data:www-data /var/run/nginx

# Set Nginx to run as www-data
# RUN sed -i 's/user nginx;/user www-data;/' /etc/nginx/nginx.conf

# Copy custom Nginx config
# COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
# Switch to non-root user
USER www-data


CMD ["nginx", "-g", "daemon off;"]
