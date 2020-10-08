#!/usr/bin/env bash

set -eu

# Prefixed variables in global scope to avoid collision. These will be set when
# __parse() is called so we only need to call parsed once.
__personnummer_century=""
__personnummer_year=""
__personnummer_month=""
__personnummer_day=""
__personnummer_day_or_coordination=""
__personnummer_serial=""
__personnummer_control=""
__personnummer_separator=""

__clear_all() {
  __personnummer_century=""
  __personnummer_year=""
  __personnummer_month=""
  __personnummer_day=""
  __personnummer_day_or_coordination=""
  __personnummer_serial=""
  __personnummer_control=""
  __personnummer_separator=""
}

# Check if passed personal identity number is valid. Will ensure a valid date is
# passed and that the Luhn checksum is correct.
valid() {
  pnr="${1:-}"

  if ! __parse "$pnr"; then
    return 1
  fi

  if (( __personnummer_serial < 1 )); then
    return 1
  fi

  # shellcheck disable=SC2119
  # Not referencing "$@" here
  luhn_value=$(format | sed 's/-//')
  luhn_value=${luhn_value:0:9}

  __personnummer_checksum=-1
  __luhn "$luhn_value"

  if [ "$__personnummer_checksum" -ne "$__personnummer_control" ]; then
    return 1
  fi

  return 0
}

# Get age returns the age of the last parsed/validated personal identity number.
# If none is found this method return -1
get_age() {
  pnr="${1:-}"

  # If an argument is given we assume it's the personal identification number
  # and thus parses it again to set all variables.
  [ -n "$pnr" ] && __parse "$pnr"

  local year
  local month
  local day
  local year_reduce=0

  read -r year month day <<< "$(date "+%Y %m %d")"

  local __personnummer_full_year=$(( __personnummer_century + __personnummer_year ))
  if (( ${__personnummer_month#0} >= month )); then
    year_reduce=1
  elif (( ${__personnummer_month#0} == month )) && (( ${__personnummer_day#0} > day )); then
    year_reduce=1
  fi

  echo $(( year - __personnummer_full_year - year_reduce ))
}

# Returns 0 (exit code 0) if the last parsed personal identity number belongs to
# a female.
is_female() {
  pnr="${1:-}"

  # If an argument is given we assume it's the personal idefnitifaction number
  # and thus parses it again to set all variables.
  [ -n "$pnr" ] && __parse "$pnr"

  local third_digit=$(( __personnummer_serial % 10))

  if (( third_digit % 2 == 0 )); then
    return 0
  fi

  return 1
}

# Returns 0 (exit code 0) if the last parsed personal identity number belongs to
# a male.
is_male() {
  if ! is_female "${1:-}"; then
    return 0
  fi

  return 1
}

# Returns 0 (exit code 0) if the last parsed personal identity number is a
# coordination number.
is_coordination_number() {
  pnr="${1:-}"

  # If an argument is given we assume it's the personal idefnitifaction number
  # and thus parses it again to set all variables.
  [ -n "$pnr" ] && __parse "$pnr"

  if [ "${__personnummer_day_or_coordination#0}" -gt 31 ]; then
    return 0
  fi

  return 1
}

# Format will echo a formatted version of the passed personal identity number.
# If a true-ish argument is given it will be echoed in long format. Capture this
# function to assign the output to a variable.
#
# shellcheck disable=SC2120
# Might be used externally
format() {
  # If there's only one argument it can be either the "boolean" to format as
  # long or the personal identification number. If the length of the argument is
  # one we assume it's a boolean and doesn't do any new parsing. If it's greater
  # than 1 however we assume it's a personal identification number and parses it
  # again after shifting the argument.
  if [ $# -eq 1 ] && [ ${#1} -gt 1 ] || [ $# -eq 2 ]; then
    pnr="${1:-}"
    shift

    __parse "$pnr"
  fi

  want_long="${1:-}"

  long=$(
  printf "%d%02d%02d-%03d%d" \
    "$(( __personnummer_century + __personnummer_year ))" \
    "${__personnummer_month#0}" \
    "${__personnummer_day_or_coordination#0}" \
    "${__personnummer_serial#0}" \
    "${__personnummer_control#0}"
  )

  if [ -n "$want_long" ]; then
    echo "$long"
  else
    echo "${long:2:${#long}}"
  fi
}


__parse() {
  pnr="${1:-}"

  # Always clear what's last parsed when trying to parse agai
  __clear_all

  if [ -z "$pnr" ]; then
    return 1
  fi

  regex="^([0-9]{2}){0,1}([0-9]{2})([0-9]{2})([0-9]{2})([-|+]{0,1})([0-9]{3})([0-9]{0,1})$"

  if [[ $pnr =~ $regex ]]; then
    __personnummer_century=$(( "${BASH_REMATCH[1]:-19}" * 100 ))
    __personnummer_year="${BASH_REMATCH[2]}"
    __personnummer_month="${BASH_REMATCH[3]}"
    __personnummer_day=$(printf "%02d" $(( "${BASH_REMATCH[4]#0}" % 60 )))
    __personnummer_day_or_coordination="${BASH_REMATCH[4]}"
    __personnummer_serial="${BASH_REMATCH[6]}"
    __personnummer_control="${BASH_REMATCH[7]}"

    # shellcheck disable=SC2034
    # This might be used in the future
    __personnummer_separator="${BASH_REMATCH[5]}"
  else
    return 1
  fi

  local date=""
  date="$(
    printf "%d%02d%02d" \
      "$(( __personnummer_century + ${__personnummer_year#0}))" \
      "${__personnummer_month#0}" \
      "${__personnummer_day#0}"
    )"

  if ! __valid_date "$date"; then
    return 1
  fi

  return 0
}

__valid_date() {
  local date="${1:-}"

  if [ "$(uname -s)" = "Darwin" ]; then
    date_result="$(date -jf"%Y%m%d" "$date" "+%Y%m%d" 2> /dev/null)"

    if [ "$date_result" = "$date" ]; then
      return 0
    fi
  else
    if date "+%Y%m%d" -d "$date" > /dev/null 2>&1; then
      return 0
    fi
  fi

  return 1
}

__luhn() {
  local series="${1:-}"
  local sum=0
  local even=1

  while read -r -n 1 digit; do
    [ "$digit" = "" ] && continue

    if [ "$even" -eq 1 ]; then
      digit=$(( "$digit" * 2 ))

      if [ "$digit" -gt 9 ]; then
        digit=$(( "$digit" - 9 ))
      fi
    fi

    sum=$(( "$sum" + "$digit" ))
    even=$(( even^1 ))
  done <<< "$series"

  __personnummer_checksum=$(( 10 - ( "$sum"  % 10 ) ))
  if [ "$__personnummer_checksum" -eq 10 ]; then
    __personnummer_checksum=0
  fi
}

# vim: set ts=2 sw=2 et:
