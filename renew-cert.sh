#!/bin/bash
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

verify_certificate_files() {
    if [ ! -f "$CERT_DIR/$DOMAIN.fullchain.pem" ] || [ ! -f "$CERT_DIR/$DOMAIN.key" ]; then
        log "Error: Certificate files are missing"
        send_slack_notification ":x: Certificate files are missing for $DOMAIN"
        exit 1
    fi
}
# Main renewal process
main() {
    log "Starting certificate issuance/renewal processes"
    send_slack_notification ":hourglass: Starting SSL certificate issuance/renewal for $DOMAIN"

    # Set up staging if enabled
    if [ "$STAGING" = true ]; then
        ACME_ARGS="--test"
        log "Running in staging mode"
        send_slack_notification "🔄 Running in staging mode"
    else
        ACME_ARGS=""
    fi

    # Issue/renew certificate
    if [ ! -f "$CERT_DIR/$DOMAIN.fullchain.pem" ] || [ ! -f "$CERT_DIR/$DOMAIN.key" ]; then
        log "No existing certificate found. Issuing new certificate..."
        send_slack_notification ":warning: No existing certificate found. Issuing new certificate..."
        
        if ! acme.sh --issue \
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
            >> "$LOG_FILE" 2>&1; then
            log "Error: Failed to issue new certificate"
            send_slack_notification ":x: Failed to issue new certificate for $DOMAIN"
            exit 1
        fi

        # Show certificate expiry date
        EXPIRY_DATE=$(openssl x509 -in "$CERT_DIR/$DOMAIN.fullchain.pem" -noout -enddate | cut -d= -f2 2>/dev/null)
        
        if [[ -n "$EXPIRY_DATE" ]]; then
            send_slack_notification ":calendar: Certificate expires on: $EXPIRY_DATE"
        else
            log "WARNING: Unable to fetch certificate expiry date"
            send_slack_notification ":warning: Unable to fetch SSL certificate expiry date."
        fi

        log "Certificate issuance completed successfully"
        send_slack_notification ":white_check_mark: SSL certificate issued successfully for $DOMAIN"
    else
        log "Attempting to renew existing certificate..."
        send_slack_notification "Attempting to renew existing certificate..."
        
        if ! acme.sh --renew \
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
            >> "$LOG_FILE" 2>&1; then
            log "Error: Failed to renew certificate"
            send_slack_notification ":x: Failed to renew SSL certificate for $DOMAIN"
            exit 1
        fi

        if [ -f "$CERT_DIR/$DOMAIN.fullchain.pem" ] && [ -f "$CERT_DIR/$DOMAIN.key" ]; then
            log "Certificate files successfully installed"
            
            # Check certificate expiry
            EXPIRY_DATE=$(openssl x509 -in "$CERT_DIR/$DOMAIN.fullchain.pem" -noout -enddate | cut -d= -f2 2>/dev/null)
            
            if [[ -n "$EXPIRY_DATE" ]]; then
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
            send_slack_notification ":x: Certificate files not found after renewal for $DOMAIN"
            exit 1
        fi
    fi

    # Verify certificate files
    verify_certificate_files
}


# Run main function
main