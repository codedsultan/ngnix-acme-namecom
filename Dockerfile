FROM nginx:alpine

# Arguments for user configuration
ARG SERVICE_USER=deploy
ARG SERVICE_GROUP=deploy
ARG SERVICE_UID=1000
ARG SERVICE_GID=1000

# Install required packages with explicit versions for better security
RUN apk add --no-cache \
    curl \
    openssl \
    socat \
    tzdata \
    bash \
    dcron \
    && rm -rf /var/cache/apk/*

# Create user and group with specified IDs
RUN addgroup -S -g ${SERVICE_GID} ${SERVICE_GROUP} || true && \
    adduser -S -u ${SERVICE_UID} -G ${SERVICE_GROUP} ${SERVICE_USER} || true

# Create necessary directories with appropriate permissions
RUN mkdir -p /etc/nginx/ssl /var/log/nginx /var/cache/nginx \
    && chown -R ${SERVICE_USER}:${SERVICE_GROUP} /etc/nginx/ssl /var/log/nginx /var/cache/nginx

# Install acme.sh with minimal permissions
WORKDIR /home/${SERVICE_USER}
USER ${SERVICE_USER}
RUN curl https://get.acme.sh | sh -s email=your-email@example.com

# Add acme.sh to PATH for service user
ENV PATH="/home/${SERVICE_USER}/.acme.sh:$PATH"

# Verify acme.sh installation
RUN ls -l /home/${SERVICE_USER}/.acme.sh
RUN /home/${SERVICE_USER}/.acme.sh/acme.sh --version || echo "acme.sh failed to run"

# Copy and set up the renewal script with appropriate permissions
USER root
COPY --chown=${SERVICE_USER}:${SERVICE_GROUP} renew-cert.sh /usr/local/bin/
# RUN chmod 700 /usr/local/bin/renew-cert.sh
RUN chmod +x /usr/local/bin/renew-cert.sh

# Configure cron for certificate renewal
RUN echo "0 3 * * * ${SERVICE_USER} /usr/local/bin/renew-cert.sh >> /var/log/cert-renewal.log 2>&1" > /etc/crontabs/root

# Set secure permissions for nginx configuration
RUN chmod 644 /etc/nginx/nginx.conf \
    && chown -R ${SERVICE_USER}:${SERVICE_GROUP} /etc/nginx/conf.d

# Remove unnecessary packages and clean up
RUN apk del curl \
    && rm -rf /var/cache/apk/*

# Set up health check
HEALTHCHECK --interval=30s --timeout=3s \
    CMD wget -q --spider http://localhost/ || exit 1

# # Configure security headers
# RUN echo "add_header X-Frame-Options DENY;" >> /etc/nginx/conf.d/default.conf \
#     && echo "add_header X-Content-Type-Options nosniff;" >> /etc/nginx/conf.d/default.conf \
#     && echo "add_header X-XSS-Protection \"1; mode=block\";" >> /etc/nginx/conf.d/default.conf \
#     && echo "add_header Content-Security-Policy \"default-src 'self';\";" >> /etc/nginx/conf.d/default.conf

# Switch to service user for running the container
USER ${SERVICE_USER}

# Start cron and Nginx with reduced privileges
CMD ["sh", "-c", "crond & nginx -g 'daemon off;'"]