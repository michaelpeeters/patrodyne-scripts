#!/bin/sh
# PatroDyne: Patron Supported Dynamic Executables, http://patrodyne.org
# MIT license: https://raw.githubusercontent.com/patrodyne/patrodyne-scripts/master/LICENSE
#
# flac2mp3.sh - Linux script to convert FLAC audio files to MP3 files.
#
# Usage:
#
#   Background: flac2mp3.sh </dev/null >flac2mp3.log 2>&1 &
#   Foreground: flac2mp3.sh 2>&1 | tee flac2mp3.log
#
# Description: This script recursively finds all files with '*.flac' suffix
# within the SOURCEDIR, it uses ffmpeg to convert each file and write the
# '*.mp3' transformation into the TARGETDIR. Hidden files are ignored. Target
# folders are created, as needed.  Files are processed in groups of parallel
# background jobs. The group size is set using the CORES variable. Set CORES to
# the number of CPU core(s) that you have (or less to reserve CPU(s) for other
# work).
#
# Set the SOURCEDIR, TARGETDIR, BITRATE and CORES for your needs.
#

SOURCEDIR="~/Music/flac"
TARGETDIR="~/Music/mp3"
BITRATE="192k"
CORES=4

BASEDIR="$(dirname $0)"
SOURCEFMT="flac"
TARGETFMT="mp3"
COUNTER=0
INDEX=0

DONE=false
find ${BASEDIR}/${SOURCEDIR} -name '*' | until ${DONE}
  do
    read SOURCE || DONE=true
    if [[ ! "${SOURCE}" =~ .*/\..* ]]; then
      TARGET=$(echo "${SOURCE}" | sed -e "s#^${BASEDIR}/${SOURCEDIR}#${BASEDIR}/${TARGETDIR}#")
      if [[ -d "${SOURCE}" && ! -e "${TARGET}" ]]; then
        mkdir -p "${TARGET}"
      elif [[ -f "${SOURCE}" && ! -e "${TARGET}" ]]; then
        if [[ "${SOURCE}" =~ .*\.${SOURCEFMT} ]]; then
          COUNTER=$(expr ${COUNTER} + 1)
          INDEX=$(expr ${INDEX} + 1)
          SOURCE[$INDEX]="${SOURCE}"
          TARGET[$INDEX]="${TARGET%.*}.${TARGETFMT}"
        else
          cp "${SOURCE}" "${TARGET}"
        fi
      fi
    fi

    if [[ "${DONE}" = "true" || $(expr ${COUNTER} % ${CORES}) -eq 0 ]]; then
      while [ ${INDEX} -gt 0 ]
        do
          echo "${COUNTER}.${INDEX}, NOCOVER: ${SOURCE[$INDEX]}"
          ffmpeg -nostdin -loglevel error -i "${SOURCE[$INDEX]}" \
            -qscale:a 0 -map_metadata 0 "${TARGET[$INDEX]}" &
          PID[INDEX]=$!
          INDEX=$(expr ${INDEX} - 1)
        done
      wait $(printf "%s " "${PID[@]}") >/dev/null 2>&1
    fi
  done
