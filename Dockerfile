FROM nginx:1.24-alpine

ARG ACME_EMAIL
ARG DEPLOY_UID=1000
ARG DEPLOY_GID=1000

# Install required packages in a single layer
RUN apk add --no-cache curl openssl socat tzdata dcron bash

# Create deploy user with configurable UID/GID
RUN addgroup -g ${DEPLOY_GID} deploy && \
    adduser -u ${DEPLOY_UID} -G deploy -h /home/deploy -s /bin/bash -D deploy

# Set up directories with proper permissions
RUN mkdir -p /usr/share/nginx/html/{app1,app2} \
            /var/cache/nginx/client_temp \
            /var/run/nginx \
            /etc/nginx/ssl \
            /etc/letsencrypt/live && \
    touch /var/log/cert-renewal.log && \
    chown -R deploy:deploy /usr/share/nginx/html \
                          /var/cache/nginx \
                          /var/run/nginx \
                          /var/log/cert-renewal.log && \
    chmod -R 750 /var/log/nginx \
                 /usr/share/nginx/html \
                 /var/cache/nginx && \
    chmod 700 /etc/nginx/ssl \
              /etc/letsencrypt/live

# Copy files with correct ownership
COPY --chown=deploy:deploy maintenance.html /usr/share/nginx/html/
COPY --chown=deploy:deploy renew-cert.sh /usr/local/bin/
RUN chmod 750 /usr/local/bin/renew-cert.sh

# Install acme.sh system-wide
ENV ACME_INSTALL_DIR="/usr/local/acme.sh"
RUN mkdir -p ${ACME_INSTALL_DIR} && \
    curl https://get.acme.sh | sh -s -- \
    --accountemail "${ACME_EMAIL}" \
    --install-dir "${ACME_INSTALL_DIR}" \
    --no-profile

# Create symlink in /usr/local/bin and set permissions
RUN ln -sf ${ACME_INSTALL_DIR}/acme.sh /usr/local/bin/acme.sh && \
    chmod -R 755 ${ACME_INSTALL_DIR}

# Add to system PATH
ENV PATH="${ACME_INSTALL_DIR}:$PATH"

# Test the installation
RUN acme.sh --version

# Set up cron job
RUN echo "0 3 * * * /usr/local/bin/renew-cert.sh >> /var/log/cert-renewal.log 2>&1" > /etc/crontabs/deploy && \
    chown deploy:deploy /etc/crontabs/deploy

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost/ || exit 1

# Use non-root user for running services
USER deploy

# Start cron and nginx with proper initialization
CMD ["sh", "-c", "crond && nginx -g 'daemon off;'"]