# Use official Nginx image as the base image
FROM nginx:alpine

# Set the maintainer label (optional)

# Set the working directory for the Nginx configuration files
# WORKDIR /etc/nginx
RUN deluser nginx && \
    adduser -u 33 -D -S -G www-data www-data
# Copy your custom Nginx configuration files
# Assuming you have a 'default.conf' and other configuration files
# COPY ./nginx.conf /etc/nginx/nginx.conf
# COPY ./conf.d/ /etc/nginx/conf.d/
RUN mkdir -p /usr/share/nginx/html /usr/share/nginx/html/nodejs/static && \
    chown -R www-data:www-data /usr/share/nginx/html /usr/share/nginx/html/nodejs/static && \
    # chmod -R 755 /usr/share/nginx/html
    chmod -R 777  /usr/share/nginx/html /usr/share/nginx/html/nodejs/static 
# Set correct file permissions for Nginx files

# Expose ports 80 and 443
EXPOSE 80 443

# Ensure Nginx runs as root for the master process, but worker processes will run as www-data
USER root

# Start Nginx in the foreground (this will prevent the container from stopping immediately)
CMD ["nginx", "-g", "daemon off;"]
