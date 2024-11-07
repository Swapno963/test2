#!/bin/ash

set -e

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

apply_migrations() {
    log "Applying database migrations..."
    local retries=5
    while [ $retries -gt 0 ]; do
        if python manage.py migrate; then
            log "Database migrations applied successfully."
            return 0
        else
            log "Failed to apply database migrations. Retrying..."
            retries=$((retries - 1))
            sleep 5
        fi
    done
    log "Database migrations failed after retries." >&2
    exit 1
}

collect_static() {
    log "Collecting static files..."
    if python manage.py collectstatic --noinput; then
        log "Static files collected successfully."
    else
        log "Failed to collect static files." >&2
        exit 1
    fi
}

main() {
    # Check dependencies
    command -v python >/dev/null 2>&1 || { log "Python is not installed." >&2; exit 1; }
    [ -f manage.py ] || { log "manage.py not found." >&2; exit 1; }

    # Apply migrations unless skipped
    if [ "$SKIP_MIGRATIONS" != "true" ]; then
        apply_migrations
    else
        log "Skipping migrations."
    fi

    # Collect static files unless skipped
    if [ "$SKIP_COLLECTSTATIC" != "true" ]; then
        collect_static
    else
        log "Skipping static file collection."
    fi

    log "Starting the application..."
    exec "$@"
}

main "$@"
