FROM nginx:alpine

# Install required packages
RUN apk add --no-cache bash curl

# Ensure required directories exist before changing ownership
RUN mkdir -p /var/cache/nginx /var/run /var/log/nginx \
    && chown -R www-data:www-data /var/cache/nginx /var/run /var/log/nginx

# Set Nginx to run as www-data
RUN sed -i 's/user nginx;/user www-data;/' /etc/nginx/nginx.conf

# Copy custom Nginx config
COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf

# Set user after permissions are set
USER www-data

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
