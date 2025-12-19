#!/bin/bash
set -e

export GIT_HTTP_MODE=${GIT_HTTP_MODE:-0} # This is whether git-http-backend is enabled. Default: disabled
export GIT_HTTP_AUTH=0 # This is whether git-http-backend comes with http basic auth. Default: disabled
export GIT_HTTP_AUTH_FILE="${GIT_HTTP_AUTH_FILE:-/srv/git/.htpasswd}" # htpasswd location

CONF_DIR="/etc/httpd/conf.d"
ACTIVE_CONF="${CONF_DIR}/git-http.conf"

# Remove any previously selected config
rm -f "${ACTIVE_CONF}"

# HTTP BASIC AUTH FOR GIT
# Options are 1=push only, 2=clone/fetch only, \
# 3=push,clone/fetch, 4=push,clone/fetch (auth for both) \
# Default: 0 = Disabled
case "${GIT_HTTP_MODE}" in
  0) ;;
  1)
    ln -s "${CONF_DIR}/git-http-p.conf" "${ACTIVE_CONF}"
    echo "Using [git-http] Using Mode 1: Authenticated Pushing Enabled"
    GIT_HTTP_AUTH=1
    ;;
  2)
    ln -s "${CONF_DIR}/git-http-cf.conf" "${ACTIVE_CONF}"
    echo "[git-http] Using Mode 2: Unauthenticated Cloning/Fetching Enabled"
    ;;
  3)
    ln -s "${CONF_DIR}/git-http-pcf.conf" "${ACTIVE_CONF}"
    echo "[git-http] Using Mode 3: Authenticated Pushing + Unauthenticated Cloning/Fetching Enabled"
    GIT_HTTP_AUTH=1
    ;;
  4)
    ln -s "${CONF_DIR}/git-http-apcf.conf" "${ACTIVE_CONF}"
    echo "[git-http] Using Mode 4: Authenticated Pushing, Cloning and Fetching Enabled"
    GIT_HTTP_AUTH=1
    ;;
  *)
    echo "[git-http] ERROR: invalid GIT_HTTP_MODE=${GIT_HTTP_MODE}" >&2
    exit 1
    ;;
esac

# Set up auth credentials for git-http-backend
if [ "$GIT_HTTP_AUTH" -eq 1 ]; then
  if [ -z "$GIT_HTTP_AUTH_USER" ] || [ -z "$GIT_HTTP_AUTH_PASSWORD" ]; then
    echo "[git-http] ERROR: Auth Enabled, but GIT_HTTP_AUTH_USER/PASSWORD is missing." >&2
    exit 1
  fi
  # If .htpasswd exists already, don't recreate it.
  if [ ! -f "$GIT_HTTP_AUTH_FILE" ]; then
    htpasswd -c -b "$GIT_HTTP_AUTH_FILE" \
      "$GIT_HTTP_AUTH_USER" "$GIT_HTTP_AUTH_PASSWORD"
    echo "[git-http] INFO: Credentials written to ${GIT_HTTP_AUTH_FILE}."
  else
    htpasswd -b "$GIT_HTTP_AUTH_FILE" \
      "$GIT_HTTP_AUTH_USER" "$GIT_HTTP_AUTH_PASSWORD"
    echo "[git-http] INFO: Using ${GIT_HTTP_AUTH_FILE} for auth credentials."
  fi

  # Ensure proper permissions for /srv/git/.htpasswd
  chown root:apache "$GIT_HTTP_AUTH_FILE"
  chmod 640 "$GIT_HTTP_AUTH_FILE"
fi

#
# HTTP BASIC AUTH FOR CGIT
if [ -n "$HTTP_AUTH_PASSWORD" ]; then
  HTTP_AUTH_USER="${HTTP_AUTH_USER:-admin}"

  # Create a .htaccess file.
  cat > /srv/www/htdocs/cgit/.htaccess <<EOF
AuthType Basic
AuthName "CGit"
AuthUserFile /srv/www/htdocs/cgit/.htpasswd
Require valid-user
EOF

  if [ ! -f /srv/www/htdocs/cgit/.htpasswd ]; then
  htpasswd -c -b /srv/www/htdocs/cgit/.htpasswd \
    "$HTTP_AUTH_USER" "$HTTP_AUTH_PASSWORD"
  else
  htpasswd -b /srv/www/htdocs/cgit/.htpasswd \
    "$HTTP_AUTH_USER" "$HTTP_AUTH_PASSWORD"
  fi

  # Ensure correct permissions for .htpasswd
  chown root:apache /srv/www/htdocs/cgit/.htpasswd
  chmod 640 /srv/www/htdocs/cgit/.htpasswd
fi

exec /usr/sbin/httpd -DFOREGROUND
