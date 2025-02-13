# ./nginx/Dockerfile
FROM nginx:alpine

ARG ACME_EMAIL="codesultan369@gmail.com"
RUN apk add --no-cache curl openssl socat tzdata

# Create deploy user (matching host UID/GID)
RUN addgroup -g 1000 deploy && \
    adduser -u 1000 -G deploy -h /home/deploy -s /bin/ash -D deploy

# Install acme.sh as deploy user
# Create directories with stricter permissions
RUN mkdir -p /usr/share/nginx/html/app1 /usr/share/nginx/html/app2 /var/cache/nginx/client_temp\
    /etc/nginx/ssl /etc/letsencrypt/live && \
    chown -R deploy:deploy /usr/share/nginx/html /var/cache/nginx && \
    chmod -R 755 /var/log/nginx /usr/share/nginx/html /var/cache/nginx && \
    chmod 755 /etc/nginx/ssl /etc/letsencrypt/live

COPY --chown=deploy:deploy maintenance.html /usr/share/nginx/html/maintenance.html
COPY --chown=deploy:deploy renew-cert.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/renew-cert.sh


RUN curl https://get.acme.sh | sh -s -- --accountemail "$ACME_EMAIL" --home /home/deploy/.acme.sh
ENV PATH="/home/deploy/.acme.sh:${PATH}"

# USER root

# Create directories with stricter permissions
# RUN mkdir -p /usr/share/nginx/html/app1 /usr/share/nginx/html/app2 \
#     /etc/nginx/ssl /etc/letsencrypt/live && \
#     chown -R deploy:deploy /usr/share/nginx/html && \
#     chmod -R 755 /var/log/nginx /usr/share/nginx/html && \
#     chmod 755 /etc/nginx/ssl /etc/letsencrypt/live

# Copy configs and scripts
# COPY --chown=deploy:deploy maintenance.html /usr/share/nginx/html/maintenance.html
# COPY renew-cert.sh /usr/local/bin/
# RUN chmod +x /usr/local/bin/renew-cert.sh

# Configure cron for deploy user
RUN echo "0 3 * * * /usr/local/bin/renew-cert.sh >> /var/log/cert-renewal.log 2>&1" > /etc/crontabs/deploy && \
    chown deploy:deploy /etc/crontabs/deploy

USER deploy

CMD ["sh", "-c", "crond && nginx -g 'daemon off;'"]