#!/usr/bin/env fish

# Ensure D-Bus session exists
if test -z "$DBUS_SESSION_BUS_ADDRESS"
    set -l dbus_output (dbus-launch --sh-syntax)
    for line in $dbus_output
        set -l parts (string split "=" $line | string trim -c "';")
        if test (count $parts) -eq 2
            set -gx $parts[1] $parts[2]
        end
    end
end

# Set GIO modules for TLS support
set -gx GIO_EXTRA_MODULES /run/current-system/sw/lib/gio/modules
set -gx SSL_CERT_FILE /etc/ssl/certs/ca-bundle.crt
set -gx SSL_CERT_DIR /etc/ssl/certs
set -gx WEBKIT_DISABLE_COMPOSITING_MODE 1
set -gx XDG_DATA_DIRS /run/current-system/sw/share:$XDG_DATA_DIRS

# Verify GIO modules directory exists
if test -d "$GIO_EXTRA_MODULES"
    echo "GIO modules found at: $GIO_EXTRA_MODULES" >&2
else
    echo "Warning: GIO_EXTRA_MODULES directory not found" >&2
end

# List TLS module
if test -f "$GIO_EXTRA_MODULES/libgiognutls.so"
    echo "TLS module found: libgiognutls.so" >&2
else
    echo "ERROR: TLS module (libgiognutls.so) not found!" >&2
    echo "WebKit will not be able to make HTTPS connections" >&2
end

# Verify keyring is accessible
if not busctl --user list | grep -q org.freedesktop.secrets
    echo "Starting gnome-keyring..." >&2
    gnome-keyring-daemon --start --components=secrets --daemonize
    sleep 1
end

# IMPORTANT: Restart broker with correct environment variables
if pgrep -f microsoft-identity-broker > /dev/null
    echo "Restarting Microsoft Identity Broker with TLS support..." >&2
    pkill -f microsoft-identity-broker
    sleep 1
end

# Start broker with environment variables
echo "Starting Microsoft Identity Broker..." >&2
env GIO_EXTRA_MODULES=$GIO_EXTRA_MODULES \
    SSL_CERT_FILE=$SSL_CERT_FILE \
    SSL_CERT_DIR=$SSL_CERT_DIR \
    WEBKIT_DISABLE_COMPOSITING_MODE=$WEBKIT_DISABLE_COMPOSITING_MODE \
    XDG_DATA_DIRS=$XDG_DATA_DIRS \
    microsoft-identity-broker &

# Wait for broker to start
sleep 2

# Verify broker is running
if not pgrep -f microsoft-identity-broker > /dev/null
    echo "ERROR: Failed to start Microsoft Identity Broker" >&2
    exit 1
end

echo "Microsoft Identity Broker started successfully" >&2

# Verify broker has correct environment
set broker_pid (pgrep -f microsoft-identity-broker)
if test -n "$broker_pid"
    if cat /proc/$broker_pid/environ | tr '\0' '\n' | grep -q "GIO_EXTRA_MODULES"
        echo "Broker has GIO_EXTRA_MODULES set ✓" >&2
    else
        echo "WARNING: Broker does not have GIO_EXTRA_MODULES set" >&2
    end
end

# Launch Intune Portal
exec intune-portal $argv
