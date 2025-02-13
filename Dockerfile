# # ./nginx/Dockerfile
# FROM nginx:alpine

# ARG ACME_EMAIL="codesultan369@gmail.com"
# RUN apk add --no-cache curl openssl socat tzdata

# # Create deploy user (matching host UID/GID)
# RUN addgroup -g 1000 deploy && \
#     adduser -u 1000 -G deploy -h /home/deploy -s /bin/ash -D deploy

# # Ensure cron group exists (if necessary)
# RUN addgroup -g 200 cron
# RUN usermod -aG cron deploy

# # Install acme.sh as deploy user
# # Create directories with stricter permissions
# RUN mkdir -p /usr/share/nginx/html/app1 /usr/share/nginx/html/app2 /var/cache/nginx/client_temp /var/run/nginx \
#     /etc/nginx/ssl /etc/letsencrypt/live && \
#     chown -R deploy:deploy /usr/share/nginx/html /var/cache/nginx /var/run/nginx && \
#     chmod -R 755 /var/log/nginx /usr/share/nginx/html /var/cache/nginx && \
#     chmod 755 /etc/nginx/ssl /etc/letsencrypt/live && \
#     touch /var/log/cert-renewal.log && \
#     chown deploy:deploy /var/log/cert-renewal.log

# COPY --chown=deploy:deploy maintenance.html /usr/share/nginx/html/maintenance.html
# COPY --chown=deploy:deploy renew-cert.sh /usr/local/bin/
# RUN chmod +x /usr/local/bin/renew-cert.sh


# RUN curl https://get.acme.sh | sh -s -- --accountemail "$ACME_EMAIL" --home /home/deploy/.acme.sh
# ENV PATH="/home/deploy/.acme.sh:${PATH}"

# # Configure cron for deploy user
# RUN echo "0 3 * * * /usr/local/bin/renew-cert.sh >> /var/log/cert-renewal.log 2>&1" > /etc/crontabs/deploy && \
#     chown deploy:deploy /etc/crontabs/deploy

# # USER deploy
# USER root

# CMD ["sh", "-c", "crond && nginx -g 'daemon off;'"]

FROM nginx:alpine

ARG ACME_EMAIL="codesultan369@gmail.com"

# Install required packages
RUN apk add --no-cache curl openssl socat tzdata dcron

# Create deploy user (matching host UID/GID)
RUN addgroup -g 1000 deploy && \
    adduser -u 1000 -G deploy -h /home/deploy -s /bin/ash -D deploy

# Ensure cron group exists (if necessary)
# RUN addgroup -g 200 cron
# RUN addgroup -S cron
# RUN usermod -aG cron deploy

# Install acme.sh as deploy user
# Create directories with stricter permissions
RUN mkdir -p /usr/share/nginx/html/app1 /usr/share/nginx/html/app2 /var/cache/nginx/client_temp /var/run/nginx \
    /etc/nginx/ssl /etc/letsencrypt/live && \
    chown -R deploy:deploy /usr/share/nginx/html /var/cache/nginx /var/run/nginx && \
    chmod -R 755 /var/log/nginx /usr/share/nginx/html /var/cache/nginx && \
    chmod 755 /etc/nginx/ssl /etc/letsencrypt/live && \
    touch /var/log/cert-renewal.log && \
    chown deploy:deploy /var/log/cert-renewal.log

# Copy necessary files
COPY --chown=deploy:deploy maintenance.html /usr/share/nginx/html/maintenance.html
COPY --chown=deploy:deploy renew-cert.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/renew-cert.sh

# Install acme.sh and set environment path
# RUN curl https://get.acme.sh | sh -s -- --accountemail "$ACME_EMAIL" --home /home/deploy/.acme.sh
# ENV PATH="/home/deploy/.acme.sh:${PATH}"
# Create the .acme.sh directory
RUN mkdir -p /home/deploy/.acme.sh

# Install acme.sh and set environment path
RUN curl https://get.acme.sh | sh -s -- --accountemail "$ACME_EMAIL" --home /home/deploy/.acme.sh

# Set the PATH environment variable for the deploy user
ENV PATH="/home/deploy/.acme.sh:${PATH}"

# Ensure permissions are correct for deploy user
RUN chown -R deploy:deploy /home/deploy/.acme.sh

# Configure cron for deploy user
RUN echo "0 3 * * * /usr/local/bin/renew-cert.sh >> /var/log/cert-renewal.log 2>&1" > /etc/crontabs/deploy && \
    chown deploy:deploy /etc/crontabs/deploy

# Switch to root user for running crond and nginx
USER root

# Start cron and nginx processes
CMD ["sh", "-c", "crond && nginx -g 'daemon off;'"]
