#!/bin/bash

function cache_snap(){
  name="$1"
  channel="$(echo "$2" | cut -d= -f2)"
  snap_line="${*}"
  mv old_snaps/"${name}"_* . || true
  old_snaps="$(find . -type f -regextype egrep -regex ".*/${name}_[0-9]+\.(snap|assert)")"
  if [[ -z "${old_snaps}" ]]; then
    echo "Downloading ${snap_line}"
    # shellcheck disable=SC2086
    snap download ${snap_line}  # write the line as-is for the rest of the command.
    sudo snap ack "${name}"_*.assert
    sudo snap install "${name}"_*.snap
  else
    metadata="$(curl -s --unix-socket /run/snapd.socket http://./v2/find?name="${name}")"
    if [[ "${RUNNER_DEBUG}" == 1 ]]; then
      echo "$metadata" | jq
    fi
    if [[ -z "${channel}" ]]; then
      channel="$(echo "$metadata" | jq -r .result[].channel)"
      if [[ ! "$channel" == */* ]]; then
        channel="latest/${channel}"
      fi
    fi
    latest_revision=$(echo "$metadata" | jq -r ".result[].channels[\"$channel\"].revision")
    if [[ ! -f "${name}_${latest_revision}.snap" ]]; then
      rm -f "${name}"*
      echo "Updating ${snap_line}"
      # shellcheck disable=SC2086
      snap download $snap_line  # write the line as-is for the rest of the command.
      sudo snap ack "${name}"_*.assert
      sudo snap install "${name}"_*.snap
    else
      echo "Already up-to-date: ${snap_line}"
    fi
  fi
}
