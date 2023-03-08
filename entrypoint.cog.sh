#!/usr/bin/env bash
# Entrypoint for creating COG (Cloud Optimized GeoTiff) images

WORKING_FOLDER=$(pwd)
GDAL_TRANSLATE_CONST_PARAMS="-b 1 -b 2 -b 3 -of COG -co TILING_SCHEME=GoogleMapsCompatible -co OVERVIEW_QUALITY=100 -co QUALITY=100"
GDALADDO_CONST_PARAMS="--config COMPRESS_OVERVIEW JPEG --config JPEG_QUALITY_OVERVIEW 100 --config PHOTOMETRIC_OVERVIEW YCBCR --config INTERLEAVE_OVERVIEW PIXEL -r average"
GDALADDO_LEVELS="2 4 8 16"

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
      gdal_translate "${CUR_FILE}" "${NEW_FILENAME}" ${GDAL_TRANSLATE_CONST_PARAMS} ${EXTRA_PARAMS}
      gdaladdo ${GDALADDO_CONST_PARAMS} "${NEW_FILENAME}" ${GDALADDO_LEVELS}
    fi
  done
else
  BASE_FILENAME=`basename "${1}"`
  NEW_FILENAME="${WORKING_FOLDER}/${BASE_FILENAME%.*}_cog.${BASE_FILENAME##*.}"
  gdal_translate "${1}" "${NEW_FILENAME}" ${GDAL_TRANSLATE_CONST_PARAMS} ${EXTRA_PARAMS}
  gdaladdo ${GDALADDO_CONST_PARAMS} "${NEW_FILENAME}" ${GDALADDO_LEVELS}
fi