#!/bin/bash

# Find the mounted configuration
export CONFIG_PATH=${CONFIG_PATH:-/config.yml}

backend_protocol=$(if [ $(yq '.backend.tls' ${CONFIG_PATH}) = true ]; then echo "https"; else echo "http"; fi)
backend_host=$(yq '.frontend.host' ${CONFIG_PATH})
backend_port=$(yq '.frontend.port' ${CONFIG_PATH})

[ ! -z "${backend_port}" ] && backend_port=":${backend_port}"
backend_path=$(yq '.backend.path' ${CONFIG_PATH})

# Create .env file from the top-level config.yml
cat > .env <<EOL
BACKEND_BASE_URL=${backend_protocol}://${backend_host}${backend_port}${backend_path}
EOL

# Generate JavaScript for runtime variable replacement
./env.sh
mv env-config.js /usr/share/nginx/html/env-config.js

# Set up nginx to use our desired port of choice
export FRONTEND_HOST=$(yq '.frontend.host' ${CONFIG_PATH})
export FRONTEND_PORT=$(yq '.frontend.port' ${CONFIG_PATH})
export BACKEND_HOST=$(yq '.backend.host' ${CONFIG_PATH})
export BACKEND_PORT=$(yq '.backend.port' ${CONFIG_PATH})
envsubst "`env | awk -F = '{printf \" \\\\$%s\", $1}'`" < /etc/nginx/conf.d/default.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'
