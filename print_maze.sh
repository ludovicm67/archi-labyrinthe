#!/bin/sh

#           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#                   Version 2, December 2004
#
# Copyright (C) 2016 Maxime Schmitt <max.schmitt@math.unistra.fr>
#
# Everyone is permitted to copy and distribute verbatim or modified
# copies of this license document, and changing it is allowed as long
# as the name is changed.
#
#            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
#   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
#
# 0. You just DO WHAT THE FUCK YOU WANT TO.


if [ $# -ne 1 ]
then
  echo "Usage: $0 <maze_file.txt>"
  exit 1
fi

awk '
function extract_powerof_two(value, power) {
  return int(value/power)%2
}
function has_right(value) {
  return extract_powerof_two(value, 2)
}
function has_bottom(value) {
  return extract_powerof_two(value, 4)
}
function is_starting_point(value) {
  return extract_powerof_two(value, 16)
}
function is_ending_point(value) {
  return extract_powerof_two(value, 32)
}
function can_i_go_out_this_way(value) {
  return extract_powerof_two(value, 64)
}
NR == 1 { x = $1; for (i=0; i < 3*x+1; ++i) printf "@"; print ""}
NR > 1 {
  printf "@"
  for (i=1; i<=NF; i++) {
    if (is_starting_point($i))
      printf "XX"
    else
      if (is_ending_point($i))
        printf "OO"
      else
        if (can_i_go_out_this_way($i))
          printf "░░"
        else
          printf "  "
    if (has_right($i))
      printf "@"
    else
      printf " "
  }
  print ""
  for (i=1; i<=NF; i++) {
    printf "@"
    if (has_bottom($i))
      printf "@@"
    else
      printf "  "
  }
  print "@"
}
' $1
