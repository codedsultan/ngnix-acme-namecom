FROM nginx:alpine

# Install required packages
RUN apk add --no-cache bash curl

# Set Nginx to run as www-data
RUN sed -i 's/user nginx;/user www-data;/' /etc/nginx/nginx.conf

# Copy custom Nginx config
COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf

# Set permissions
RUN chown -R www-data:www-data /var/cache/nginx /var/run /var/log/nginx

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
