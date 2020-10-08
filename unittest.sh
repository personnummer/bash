#!/usr/bin/env bash

source personnummer.sh
source critic.sh

_describe "Invalid dates"
  for tc in "19901301-1111" "20150229-1234" "2017-02-29" "" "not-a-date"; do
    _test "Should not be valid" valid $tc
      _assert _return_false
  done

_describe "Invalid last four digits"
  for tc in "19900101-1111" "20160229-1111" "6403273814" "20150916-0006"; do
    _test "Should not be valid" valid $tc
      _assert _return_false
  done

_describe "Valid personal identity numbers"
  for tc in "19900101-0017" "196408233234" "000101-0107" "510818-9167" "19130401+2931"; do
    _test "Should be valid" valid $tc
      _assert _return_true
  done

_describe "Formatting personal identity numbers"
  for tc in "19900101-0017" "9001010017" "900101+0017"; do
    __parse "$tc"

    _test "corret short format for $tc" format
      _assert _output_equals "900101-0017"
    _test "corret long format for $tc" format 1
      _assert _output_equals "19900101-0017"
      _assert _nth_arg_equals 0 1

    # Clear all so we assure that we use the argument as value
    __clear_all

    _test "corret short format for $tc as arg" format $tc
      _assert _output_equals "900101-0017"
      _assert _nth_arg_equals 0 "$tc"

    _test "corret short format for $tc as arg" format $tc 1
      _assert _output_equals "19900101-0017"
      _assert _nth_arg_equals 0 "$tc"
      _assert _nth_arg_equals 1 1
  done

_describe "Age from personal identity numbers"
  year=""
  month=""
  day=""

  read -r year month day <<< "$(date "+%Y %m %d")"

  next_year=$year
  next_month=$(( month + 1 ))
  if [ "$month" -eq 12 ]; then
    next_year=$(( year + 1 ))
    next_month=1
  fi

  prev_year=$year
  prev_month=$(( month - 1 ))
  if [ "$month" -eq 1 ]; then
    prev_year=$(( year - 1 ))
    prev_month=12
  fi

  twenty_next_month=$(printf "%d%02d%02d" $(( next_year - 20)) "${next_month#0}" 1 )
  twenty_prev_month=$(printf "%d%02d%02d" $(( prev_year - 20 )) "${prev_month#0}" 1 )
  hundred=$(printf "%d%02d%02d" $(( "$year" - 100 )) 1 1)

  for tc in "$twenty_next_month-1111 19" "$twenty_prev_month-2222 20" "$hundred-3333 100"; do
    read -r pnr age <<< "$tc"
    __parse "$pnr"

    _test "corret age for $tc" get_age
      _assert _output_equals "$age"
    _test "corret age for $tc with arg" get_age "$pnr"
      _assert _output_equals "$age"
      _assert _nth_arg_equals 0 "$pnr"
  done

_describe "Valid gender for personal identity numbers"
  for tc in "19900101-0017 m" "19090903-6600 f" "800101-3294 m" "000903-6609 f" "800101+3294 m"; do
    read -r pnr gender <<< "$tc"
    __parse "$pnr"

    if [ "$gender" = "m" ]; then
      _test "Should be classified as male" is_male
        _assert _return_true
      _test "Should NOT be classified as female" is_female
        _assert _return_false
    else
      _test "Should be classified as female" is_female
        _assert _return_true
      _test "Should NOT be classified as male" is_male
        _assert _return_false
    fi

  done

_describe "Valid coordination number for personal identity numbers"
  for tc in "800161-3294 1" "800101-3294 0" "640327-3813 0"; do
    read -r pnr coordination <<< "$tc"
    __parse "$pnr"

    if [ "$coordination" -gt 0 ]; then
      _test "Should be classified as coordination number" is_coordination_number
        _assert _return_true
      _test "Should be classified as coordination number with argument" is_coordination_number "$pnr"
        _assert _return_true
        _assert _nth_arg_equals 0 "$pnr"

    else
      _test "Should NOT be classified as coordination number" is_coordination_number
        _assert _return_false
      _test "Should NOT be classified as coordination number with argument" is_coordination_number "$pnr"
        _assert _return_false
        _assert _nth_arg_equals 0 "$pnr"
    fi

  done

# vim: set ts=2 sw=2 et:
