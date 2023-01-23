#!/usr/bin/env bash
# Entrypoint for STAC server docker image

if [ "${STAC_URL}" == "" ]; then
  STAC_URL="${1}"
fi

if [ "${STAC_URL}" == "" ]; then
  echo "STAC Catalog URL not specified on the command line"
  exit 1
fi

cd /stac-browser && npm start -- --open "--CATALOG_URL=${STAC_URL}"