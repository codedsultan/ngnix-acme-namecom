FROM nginx:alpine

# Install required packages
RUN apk add --no-cache bash curl

# Ensure www-data user and group exist only if missing
# RUN getent group www-data || addgroup -g 33 -S www-data && \
#     getent passwd www-data || adduser -u 33 -D -S -G www-data www-data

RUN deluser nginx && \
    adduser -u 33 -D -S -G www-data www-data

# Configure directories and permissions
RUN mkdir -p /var/cache/nginx /var/run /var/log/nginx && \
    chown -R www-data:www-data /var/cache/nginx /var/run /var/log/nginx /etc/nginx  /usr/share/nginx/html && \
    chmod -R 755 /var/cache/nginx /var/run /var/log/nginx /etc/nginx  /usr/share/nginx/html 

# Ensure required directories exist before changing ownership
# RUN mkdir -p /var/cache/nginx /var/run /var/www/errors /var/www/laravel/public /var/www/laravel/storage /var/www/nodejs/static /var/log/nginx /var/run/nginx /var/cache/nginx/client_temp && \
#     chown -R www-data:www-data /var/www/errors /var/www/laravel/public /var/www/laravel/storage /var/www/nodejs/static /var/log/nginx /var/run/nginx 
# Create necessary directories and set permissions
# RUN chown -R www-data:www-data /var/cache/nginx /var/run /var/log/nginx && \
#     chmod -R 755 /var/cache/nginx /var/run /var/log/nginx

# RUN chown -R nginx:nginx /var/cache/nginx /var/run /var/log/nginx /etc/nginx /usr/share/nginx/html && \
#     chmod -R 755 /var/cache/nginx /var/run /var/log/nginx /etc/nginx /usr/share/nginx/html 

# Configure nginx to run as www-data
# RUN sed -i 's/user  nginx/user  www-data/g' /etc/nginx/nginx.conf

# Update permissions for nginx directories
RUN chown -R www-data:www-data /etc/nginx && \
    chmod -R 755 /etc/nginx

    
# RUN mkdir -p /usr/share/nginx/html && \
#     chown -R www-data:www-data /usr/share/nginx/html && \
#     chmod -R 755 /usr/share/nginx/html

# RUN mkdir -p /var/www/errors /var/www/laravel/public /var/www/laravel/storage /var/www/nodejs/static /var/log/nginx  && \
#     chown -R www-data:www-data /var/www/errors /var/www/laravel/public /var/www/laravel/storage /var/www/nodejs/static /var/log/nginx 

# Set Nginx to run as www-data
# RUN sed -i 's/user nginx;/user www-data;/' /etc/nginx/nginx.conf

# Copy custom Nginx config
# COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
# Switch to non-root user
USER www-data


CMD ["nginx", "-g", "daemon off;"]
