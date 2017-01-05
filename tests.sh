#!/bin/bash --norc
# Copyright (c) 2017 Yu-Jie Lin
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

PSI=$'\001\001'
PEI=$'\001\002'
RST=$"${PSI}\033[0m${PEI}"
FRD=$"${PSI}\033[1;31m${PEI}"
FGN=$"${PSI}\033[1;32m${PEI}"
FBL=$"${PSI}\033[1;34m${PEI}"
FMG=$"${PSI}\033[1;35m${PEI}"
FWN=$"${PSI}\033[1;37m${PEI}"
UPT=$"${FBL}\$${RST}"
DIR=$"${FRD}/"

FIFO='/tmp/.vimps1_test_fifo'

run_tests()
{
  local func
  ctest=0
  cpass=0
  cfail=0
  for func in $(declare -F | cut -d ' ' -f 3); do
    [[ $func != test_* ]] && continue
    rm -f "$FIFO"
    printf "testing $func... "
    pass=y
    if ! $func; then
      ((ctest++, cfail++))
      printf "${FRD}FAIL${RST}\n"
      cat < "$FIFO"
    fi

    if [[ $pass == y ]]; then
      ((ctest++, cpass++))
      printf "${FGN}pass${RST}\n"
    else
      ((ctest++, cfail++))
      printf "${FRD}FAIL${RST}\n"
      cat < "$FIFO"
    fi
    rm -f "$FIFO"
  done
  echo

  printf "=== ${FUNCNAME[1]} summary ===\n"
  printf "Total  tests: %3d\n" $ctest
  printf "Passed tests: ${FGN}%3d${RST}\n" $cpass
  printf "Failed tests: ${FRD}%3d${RST}\n" $cfail
}

differ()
{
  diff -u <(printf "$e" | cat -v) <(printf "$r" | cat -v)
}

ast_eq()
{
  if [[ "$(printf "$e")" != "$r" ]]; then
    differ >> "$FIFO"
    pass=n
  fi
}

x()
{
  local c=${2:-0}
  local w=${3:-78}
  printf "PWD = $1\n" >> "$FIFO"
  printf "RET = $c\n" >> "$FIFO"
  printf "COL = $w\n" >> "$FIFO"
  printf "EXP = $e\n" >> "$FIFO"
  r="$(PWD="$1" COLUMNS="$w" vimps1 "$c")"
  printf "RES = $r\n" >> "$FIFO"
}

tests()
{
  test__enable()
  {
    enable -f $PWD/vimps1 vimps1
  }

  test_root()
  {
    e=$" ${DIR}${FGN} ${UPT} "
    x "/"
    ast_eq
  }

  test_home()
  {
    e=$" ${FMG}~ ${UPT} "
    x "$HOME"
    ast_eq
  }

  test_no_abbr()
  {
    e=$" ${DIR}${FGN}foo ${UPT} "
    x "/foo"
    ast_eq

    e=$" ${DIR}${FGN}foobar ${UPT} "
    x "/foobar"
    ast_eq
  }

  test_abbrs()
  {
    e=$" ${DIR}${FWN}foob${DIR}${FGN}test ${UPT} "
    x "/foobar/test"
    ast_eq

    e=$" ${DIR}${FWN}foob${DIR}${FWN}test${DIR}${FGN}dirs ${UPT} "
    x "/foobar/tests/dirs"
    ast_eq

    e=$" ${DIR}${FGN}foo${DIR}${FWN}test${DIR}${FGN}dirs ${UPT} "
    x "/foo/tests/dirs"
    ast_eq
  }

  test_abbr_nonprintable()
  {
    e=$" ${DIR}${FGN}a?b ${UPT} "
    x "/a	b"
    ast_eq

    e=$" ${DIR}${FGN}a?b?${DIR}${FGN}d ${UPT} "
    printf -v d $"/a\tb\003/d"
    x "$d"
    ast_eq
  }

  test_abbr_unicode()
  {
    e=$" ${DIR}${FGN}中國語 ${UPT} "
    x "/中國語"
    ast_eq

    e=$" ${DIR}${FWN}中國${DIR}${FGN}test ${UPT} "
    x "/中國語/test"
    ast_eq

    e=$" ${DIR}${FWN}中 ${DIR}${FGN}test ${UPT} "
    x "/中 國 語/test"
    ast_eq
  }

  test_exit_1()
  {
    e=$"\033[41;1;37m         \033[4G1\033[0m\n${RST}"
    e+=$" ${DIR}${FGN} ${UPT} "
    x "/" 1 9
    ast_eq
  }

  run_tests
}

tests
