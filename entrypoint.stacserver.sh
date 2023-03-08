#!/usr/bin/env sh
# Entrypoint for STAC server docker image

CERT_FILE="${CERT_FILE:-/cert.pem}"
echo "Looking for default SSL certificate file: ${CERT_FILE}"

HTTPS_OPTIONS=""
if [ -e "${CERT_FILE}" ]; then
    HTTPS_OPTIONS="-S -C ${CERT_FILE}"
    echo "Using HTTPS options: ${HTTPS_OPTIONS}"
else
echo "  ... not found"
fi

http-server /stac-browser/dist/ ${HTTPS_OPTIONS}
