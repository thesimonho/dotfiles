#!/usr/bin/env bash

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  doctor_bold=$'\033[1m'
  doctor_green=$'\033[32m'
  doctor_red=$'\033[31m'
  doctor_yellow=$'\033[33m'
  doctor_reset=$'\033[0m'
else
  doctor_bold=""
  doctor_green=""
  doctor_red=""
  doctor_yellow=""
  doctor_reset=""
fi

doctor_header() {
  printf '%s==> %s%s\n' "$doctor_bold" "$1" "$doctor_reset"
}

doctor_ok() {
  printf '%sok%s' "$doctor_green" "$doctor_reset"
}

doctor_missing() {
  printf '%smissing%s' "$doctor_red" "$doctor_reset"
}

doctor_warn() {
  printf '%s%s%s' "$doctor_yellow" "$1" "$doctor_reset"
}
