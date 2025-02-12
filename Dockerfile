# ./nginx/Dockerfile
FROM nginx:alpine

ARG ACME_EMAIL="codesultan369@gmail.com"
# Install required packages
RUN apk add --no-cache \
    curl \
    openssl \
    socat \
    tzdata \
    bash \
    dcron 

# Create deploy user (same UID/GID as host deploy user)
RUN addgroup -g 1000 deploy && \
    adduser -u 1000 -G deploy -h /home/deploy -s /bin/bash -D deploy

# Install acme.sh as deploy user
USER deploy
# RUN curl https://get.acme.sh | sh -s -- --accountemail "$ACME_EMAIL"
RUN curl https://get.acme.sh | sh -s -- --accountemail "$ACME_EMAIL" --home /etc/acme.sh

# Add acme.sh and local bin to PATH
# ENV PATH="/home/deploy/.acme.sh:/home/deploy/.local/bin:${PATH}"
ENV PATH="/etc/acme.sh:/home/deploy/.local/bin:${PATH}"


# # Verify acme.sh installation
# RUN ls -l /home/deploy/.acme.sh
# RUN /home/deploy/.acme.sh/acme.sh --version || echo "acme.sh failed to run"

# Verify acme.sh installation
RUN ls -l /etc/acme.sh
RUN /etc/acme.sh/acme.sh --version || echo "acme.sh failed to run"

USER root

# Create directories and set permissions
RUN mkdir -p /usr/share/nginx/html/app1 /usr/share/nginx/html/app2 /etc/nginx/ssl /etc/letsencrypt/live && \
    chown -R deploy:deploy /usr/share/nginx/html /etc/nginx/ssl /etc/letsencrypt

# Copy nginx config and maintenance page
# COPY --chown=deploy:deploy nginx.conf /etc/nginx/conf.d/default.conf
COPY --chown=deploy:deploy maintenance.html /usr/share/nginx/html/maintenance.html

# Copy and set up the renewal script
COPY renew-cert.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/renew-cert.sh && chown deploy:deploy /usr/local/bin/renew-cert.sh

# Ensure deploy can write logs
RUN touch /var/log/cert-renewal.log && chown deploy:deploy /var/log/cert-renewal.log

# Add cron job under root (deploy needs sudo for nginx)
# RUN echo "0 3 * * * /usr/local/bin/renew-cert.sh >> /var/log/cert-renewal.log 2>&1" > /etc/crontabs/root
RUN echo "0 3 * * * deploy /usr/local/bin/renew-cert.sh >> /var/log/cert-renewal.log 2>&1" > /etc/crontabs/root


# Switch back to root before running CMD
USER root

# Start cron and Nginx
# CMD ["sh", "-c", "crond & nginx -g 'daemon off;'"]
CMD ["sh", "-c", "exec crond && exec nginx -g 'daemon off;'"]

