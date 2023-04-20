#!/usr/bin/env bash
# Entrypoint for creating COG (Cloud Optimized GeoTiff) images

WORKING_FOLDER=$(pwd)
GDAL_TRANSLATE_CONST_PARAMS="-of COG -co TILING_SCHEME=GoogleMapsCompatible -co OVERVIEW_QUALITY=100 -co QUALITY=100"
GDALADDO_CONST_PARAMS="--config COMPRESS_OVERVIEW JPEG --config JPEG_QUALITY_OVERVIEW 100 --config PHOTOMETRIC_OVERVIEW YCBCR --config INTERLEAVE_OVERVIEW PIXEL -r average"
GDALADDO_LEVELS="2 4 8 16"
HAVE_COMPRESSION=0

# Make sure we have a parameter
if [ "$1"  == "" ]; then
  echo "Please specify a file or folder and try again"
  exit 1
fi

# Function for determining number of bands and returning GDAL_TRANSLATE parameter
_get_gdal_bands() {
  RETURN_GDAL=""

  SAVEIFS=$IFS
  IFS=$(echo -en "\n\b")

  for i in $( gdalinfo ${1} | grep Band ); do
    IFS=$SAVEIFS
    HAVE_BAND=0
    for p in $i; do
      case $p in
        Band)
          HAVE_BAND=1
          ;;
        0|1|2|3|4|5|6|7|8|9)
          if [[ "${HAVE_BAND}" == "1" ]]; then
            RETURN_GDAL="${RETURN_GDAL} -b ${p}"
          fi
          HAVE_BAND=0
          ;;
        *)
          HAVE_BAND=0
          ;;
      esac
    done
    IFS=$(echo -en "\n\b")
  done

 IFS=$SAVEIFS

 echo "${RETURN_GDAL}"
}

# Function for determining channel width and returning GDAL_TRANSLATE compression type
_get_gdal_compression() {
  # Default compression
  RETURN_COMPRESSION="LZW"

  # Check if we're to actually return compression (when the option is set)
  if [[ "${2}" != "1" ]]; then
    echo ""
    return 0
  fi

  SAVEIFS=$IFS
  IFS=$(echo -en "\n\b")

  for i in $( gdalinfo ${1} | grep Type ); do
    IFS=$SAVEIFS
    for p in $i; do
      case $p in
        Type=Byte,|Type=Int8,)
          RETURN_COMPRESSION="JPEG"
          ;;
        *)
          ;;
      esac
    done
    IFS=$(echo -en "\n\b")
  done

 IFS=$SAVEIFS

 echo "-co COMPRESS=${RETURN_COMPRESSION}"
}

# Check for extra parameters
EXTRA_PARAMS=""
if [[ "${2}" != "" ]]; then
  if [[ "${2}" == "COMPRESS" ]]; then
    HAVE_COMPRESSION=1
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
        CUR_FILE=$(realpath "${ONE_FILE}")
        ;;
      ".TIF")
        CUR_FILE=$(realpath "${ONE_FILE}")
        ;;
    esac
    case "${ONE_FILE: -5}" in
      ".tiff")
        CUR_FILE=$(realpath "${ONE_FILE}")
        ;;
      ".TIFF")
        CUR_FILE=$(realpath "${ONE_FILE}")
        ;;
    esac
    if [[ "${CUR_FILE}" != "" ]]; then
      BASE_FILENAME=`basename "${CUR_FILE}"`
      NEW_FILENAME="${WORKING_FOLDER}/${BASE_FILENAME%.*}_cog.${BASE_FILENAME##*.}"
      GDAL_BANDS=$(_get_gdal_bands "${CUR_FILE}")
      GDAL_COMPRESSION=$(_get_gdal_compression "${CUR_FILE}" "${HAVE_COMPRESSION}")
      gdal_translate "${CUR_FILE}" "${NEW_FILENAME}" ${GDAL_BANDS} ${GDAL_COMPRESSION} ${GDAL_TRANSLATE_CONST_PARAMS} ${EXTRA_PARAMS}
      gdaladdo ${GDALADDO_CONST_PARAMS} "${NEW_FILENAME}" ${GDALADDO_LEVELS}
    fi
  done
else
  BASE_FILENAME=`basename "${1}"`
  NEW_FILENAME="${WORKING_FOLDER}/${BASE_FILENAME%.*}_cog.${BASE_FILENAME##*.}"
  GDAL_BANDS=$(_get_gdal_bands "${1}")
  GDAL_COMPRESSION=$(_get_gdal_compression "${1}" "${HAVE_COMPRESSION}")
  gdal_translate "${1}" "${NEW_FILENAME}" ${GDAL_BANDS} ${GDAL_COMPRESSION} ${GDAL_TRANSLATE_CONST_PARAMS} ${EXTRA_PARAMS}
  gdaladdo ${GDALADDO_CONST_PARAMS} "${NEW_FILENAME}" ${GDALADDO_LEVELS}
fi
