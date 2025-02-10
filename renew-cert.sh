#!/bin/bash
set -e

# Configuration
LOG_FILE="/var/log/cert-renewal.log"
CERT_DIR="/etc/letsencrypt/live"
DOMAIN="${DOMAIN}"
STAGING="${STAGING}" #//false  # Set to true for testing
EMAIL="${EMAIL}"

SLACK_WEBHOOK_URL="${SLACK_MONITORING_WEB_HOOK}" 

export Namecom_Username="${NAMECOM_USERNAME}"
export Namecom_Token="${NAMECOM_TOKEN}"
# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/cert-renewal.log
}

send_slack_notification() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    log "Sending Slack notification: $message"
    curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"${message}\"}" "$SLACK_WEBHOOK_URL"
}
# Check if we're running as the correct user
# if [ "$(id -u)" = "0" ]; then
#     log "Error: This script should not be run as root"
#     send_slack_notification ":x: ERROR: This script should not be run as root"
#     exit 1
# fi

# Function to reload Nginx
reload_nginx() {
    log "Reloading Nginx configuration..."
    send_slack_notification "🔄 Reloading Nginx configuration..."
    # nginx -t && nginx -s reload
    # Reload Nginx with new certificates
    if nginx -t && nginx -s reload; then
        log_message "Nginx reloaded successfully"
        send_slack_notification ":rocket: Nginx reloaded successfully with the new certificate"
    else
        log_message "WARNING: Nginx reload failed!"
        send_slack_notification ":warning: Nginx reload failed!"
    fi
}

# Main renewal process
main() {
    log "Starting certificate issuance/renewal processes"
    send_slack_notification ":hourglass: Starting SSL certificate issuance/renewal for $DOMAIN"

    # Set up staging if enabled
    # if [ "$STAGING" = true ]; then
    #     ACME_ARGS="--test"
    #     log "Running in staging mode"
    #     send_slack_notification "🔄 Running in staging mode"
    # else
    #    ACME_ARGS=""
    # fi

    # Issue/renew certificate
    if [! -f "$CERT_DIR/$DOMAIN.fullchain.pem" ] && [! -f "$CERT_DIR/$DOMAIN.key" ]; then
        log "No existing certificate found. Issuing new certificate..."
        send_slack_notification ":warning: No existing certificate found. Issuing new certificate..."
        acme.sh --issue \
        --dns dns_namecom \
        -d "$DOMAIN" \
        -d "*.$DOMAIN" \
        --server letsencrypt \
        --keylength 4096 \
        --email "$EMAIL" \
        --key-file "$CERT_DIR/$DOMAIN.key" \
        --fullchain-file "$CERT_DIR/$DOMAIN.fullchain.pem" \
        --reloadcmd "nginx -s reload" \
        --force \
        >> $LOG_FILE 2>&1; 

        # Show certificate expiry date
        EXPIRY_DATE=$(openssl x509 -in "$CERT_DIR/$DOMAIN.fullchain.pem" -noout -enddate | cut -d= -f2 || echo "")
        
        if [[ -n "$EXPIRY_DATE" ]]; then  # Check if EXPIRY_DATE is set before sending notification
            send_slack_notification ":calendar: Certificate expires on: $EXPIRY_DATE"
        else
            log "WARNING: Unable to fetch certificate expiry date"
            send_slack_notification ":warning: Unable to fetch SSL certificate expiry date."
        fi

        log "Certificate renewal completed successfully"
        send_slack_notification ":white_check_mark: SSL certificate renewed successfully for $DOMAIN"
    else
        log "Attempting to renew existing certificate..."
        send_slack_notification "Attempting to renew existing certificate..."
        acme.sh --renew \
        --dns dns_namecom \
        -d $DOMAIN \
        -d "*.$DOMAIN" \
        --server letsencrypt \
        --keylength 4096 \
        --email "$EMAIL" \
        --key-file "$CERT_DIR/$DOMAIN.key" \
        --fullchain-file "$CERT_DIR/$DOMAIN.fullchain.pem" \
        --reloadcmd "nginx -s reload" \
        --force \
        >> $LOG_FILE 2>&1;
        
    fi

    # Verify certificate files
    if [ -f "$CERT_DIR/$DOMAIN.fullchain.pem" ] && [ -f "$CERT_DIR/$DOMAIN.key" ]; then
        log "Certificate files successfully installed"
        # Check certificate expiry
        EXPIRY_DATE=$(openssl x509 -in "$CERT_DIR/$DOMAIN.fullchain.pem" -noout -enddate | cut -d= -f2 || echo "")
        
        if [[ -n "$EXPIRY_DATE" ]]; then  # Check if EXPIRY_DATE is set before sending notification
            send_slack_notification ":calendar: Certificate expires on: $EXPIRY_DATE"
        else
            log "WARNING: Unable to fetch certificate expiry date"
            send_slack_notification ":warning: Unable to fetch SSL certificate expiry date."
        fi
        
        reload_nginx
        log "Certificate renewal completed successfully"
        send_slack_notification ":white_check_mark: SSL certificate renewed successfully for $DOMAIN"
    else
        log "Error: Certificate files not found after renewal"
        exit 1
    fi
}

# Run main function
main