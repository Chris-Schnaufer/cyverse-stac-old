#!/usr/bin/env bash
# Entrypoint for creating COG (Cloud Optimized GeoTiff) images

WORKING_FOLDER=$(pwd)

# Make sure we have a parameter
if [ "$1"  == "" ]; then
  echo "Please specify a file or folder and try again"
  exit 1
fi

# Check for extra parameters
EXTRA_PARAMS=""
if [[ "${2}" != "" ]]; then
  if [[ "${2}" == "COMPRESS" ]]; then
      EXTRA_PARAMS="${EXTRA_PARAMS} -co COMPRESS=JPEG"
  fi
fi

# Check if we have a file or a folder
if [[ -d "${WORKING_FOLDER}/$1" ]]; then
  echo "Processing all .tif/.tiff files in a folder"
  for ONE_FILE in "${WORKING_FOLDER}/$1"/*; do
    # Get the meaningful file names
    CUR_FILE=""
    case "${ONE_FILE: -4}" in
      ".tif")
        CUR_FILE="${ONE_FILE}"
        ;;
      ".TIF")
        CUR_FILE="${ONE_FILE}"
        ;;
    esac
    case "${ONE_FILE: -5}" in
      ".tiff")
        CUR_FILE="${ONE_FILE}"
        ;;
      ".TIFF")
        CUR_FILE="${ONE_FILE}"
        ;;
    esac
    if [[ "${CUR_FILE}" != "" ]]; then
      BASE_FILENAME=`basename "${CUR_FILE}"`
      NEW_FILENAME="${WORKING_FOLDER}/${BASE_FILENAME%.*}_cog.${BASE_FILENAME##*.}"
      gdal_translate "${CUR_FILE}" "${NEW_FILENAME}" -of COG ${EXTRA_PARAMS}
    fi
  done
else
  BASE_FILENAME=`basename "${CUR_FILE}"`
  NEW_FILENAME="${WORKING_FOLDER}/${BASE_FILENAME%.*}_cog.${BASE_FILENAME##*.}"
  gdal_translate "${1}" "${NEW_FILENAME}" -of COG ${EXTRA_PARAMS}
fi