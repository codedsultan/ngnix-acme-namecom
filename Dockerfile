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

# Install acme.sh system-wide with proper setup
RUN cd /tmp && \
    curl https://raw.githubusercontent.com/acmesh-official/acme.sh/master/acme.sh -o acme.sh && \
    chmod +x acme.sh && \
    ./acme.sh --install \
      --home /usr/local/acme.sh \
      --accountemail "${ACME_EMAIL}" \
      --no-profile && \
    rm -f acme.sh
# ENV HOME="/usr/local"
# RUN curl https://get.acme.sh | sh -s email=my@example.com
RUN curl -o /usr/local/acme.sh/dnsapi/dns_namecom.sh https://raw.githubusercontent.com/acmesh-official/acme.sh/master/dnsapi/dns_namecom.sh
# Add acme.sh to PATH
# ENV PATH="/root/.acme.sh:$PATH"    
# Add acme.sh to PATH
# Set HOME environment variable
ENV PATH="/usr/local/acme.sh:$PATH"


# Test the installation
RUN acme.sh --version
# Set up cron job
RUN echo "0 3 * * * /usr/local/bin/renew-cert.sh >> /var/log/cert-renewal.log 2>&1" > /etc/crontabs/deploy && \
    chown deploy:deploy /etc/crontabs/deploy


# Add healthcheck
# HEALTHCHECK --interval=30s --timeout=3s \
#   CMD curl -f http://localhost/ || exit 1

# Use non-root user for running services
# USER deploy

# Start cron and nginx with proper initialization
CMD ["sh", "-c", "crond && nginx -g 'daemon off;'"]