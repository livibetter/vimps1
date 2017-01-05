#!/bin/bash --norc
# Copyright (c) 2011, 2014-2017 Yu-Jie Lin
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

trap 'kill $tmpcount_pid ; rm -f "$tmpcount"; exit 130' INT

test_command () {

  echo "Benchmarking ${TD[@]}"
  echo -n "Please wait for 5 seconds..."
  tmpcount="$(mktemp)"
  ( trap exit TERM; "${SETUP[@]}"; while :; do ${TD[@]}; echo >> "$tmpcount"; done ) &>/dev/null &
  tmpcount_pid=$!
  sleep 5
  kill $tmpcount_pid
  echo -ne "\033[3K\033[0G$(bc <<< "$(wc -l < "$tmpcount") / 5") prompts per second via $VIA.\n"
  rm "$tmpcount"

}

bash_ps1 () {
  local STR_MAX_LENGTH dirnames p d i

  STR_MAX_LENGTH=3

  echo -n ' '

  p=${PWD/$HOME/}
  [[ "$p" != "$PWD" ]] && echo -n '~'
  if [[ ! -z "$p" ]]; then
  until [[ "$p" == "$d" ]]; do
    p=${p#*/}
    d=${p%%/*}
    dirnames[${#dirnames[@]}]="$d"
  done
  fi

  for ((i = 0; i < ${#dirnames[@]}; i++)); do
    if ((i == ${#dirnames[@]} - 1)) || ((${#dirnames[i]} <= STR_MAX_LENGTH)); then
      echo -n "/${dirnames[i]}"
    else
      echo -n "/${dirnames[i]:0:$STR_MAX_LENGTH}"
    fi
  done

}

SETUP=('enable' '-f' "$PWD/vimps1" 'vimps1')
VIA='vimps1'
TD=(vimps1)

test_command

SETUP=()
VIA='Bash PS1'
TD=(bash_ps1)

test_command
