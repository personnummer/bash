#!/usr/bin/env bash

source personnummer.sh
source critic.sh

_describe "Invalid dates"
    _test "Should test invalid dates" false
      for tc in "19901301-1111" "2017-02-29" "" "not-a-date"; do
        _assert "! valid $tc" "invaid date '$tc'"
      done

_describe "Invalid last four digits"
    _test "Should test invalid social security numbers" false
      for tc in "19900101-1111" "20160229-1111" "6403273814"; do
        _assert "! valid $tc" "invaid last digits '$tc'"
      done

_describe "Valid social security numbers"
    _test "Should test valid social security numbers" false
      for tc in "19900101-0017" "196408233234" "000101-0107" "510818-9167" "19130401+2931"; do
        _assert "valid $tc" "valid '$tc'"
      done

_describe "Formatting social security numbers"
    _test "Should format social security number" false
      for tc in "19900101-0017" "9001010017" "900101+0017" ; do
        __parse "$tc"
        _assert "[ $(format) = 900101-0017 ]" "correct short format for $tc"
        _assert "[ $(format 1) = 19900101-0017 ]" "correct long format for $tc"
      done

# TODO: Create dynamic dates.
_describe "Age from social security numbers"
    _test "Should test age" false
      for tc in "19900101-0017 30"; do
        read -r pnr age <<< "$tc"
        __parse "$pnr"
        _assert "[ $(get_age) -eq $age ]" "correct age for $tc"
      done

_describe "Valid gender for social security numbers"
    _test "Should test valid gender or social security numbers" false
      for tc in "19900101-0017 m" "19090903-6600 f" "800101-3294 m" "000903-6609 f" "800101+3294 m"; do
        read -r pnr gender <<< "$tc"
        __parse "$pnr"

        if [ "$gender" = "m" ]; then
          _assert "is_male"     "correct gender for $pnr (male)"
          _assert "! is_female" "correct gender for $pnr (not female)"
        else
          _assert "is_female" "correct gender for $pnr (female)"
          _assert "! is_male"     "correct gender for $pnr (not male)"
        fi

      done

_describe "Valid coordination number for social security numbers"
    _test "Should test valid coordination or social security numbers" false
      for tc in "800161-3294 1" "800101-3294 0" "640327-3813 0"; do
        read -r pnr coordination <<< "$tc"
        __parse "$pnr"

        if [ "$coordination" -gt 0 ]; then
          _assert "is_coordination_number" "correct coordination number for $pnr (yes)"
        else
          _assert "! is_coordination_number" "correct coordination number for $pnr (no)"
        fi

      done

# vim: set ts=2 sw=2 et:
