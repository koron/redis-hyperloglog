#!/bin/sh

bits=4

redis-cli DEL set1 > /dev/null
redis-cli DEL set2 > /dev/null
redis-cli DEL set3 > /dev/null
redis-cli DEL set4 > /dev/null

add() {
  key=$1 ; shift
  value=$1 ; shift
  hash=`./mmh3 ${value}`
  redis-cli --eval ./hll_add.lua $key , $bits $hash > /dev/null
}

addset() {
  key=$1 ; shift
  start=$1 ; shift
  end=$1 ; shift
  step=$1 ; shift
  for i in `seq $start $step $end` ; do
    add $key "item${i}"
  done
}

addset set1 1 50 1
addset set2 51 100 1
addset set3 1 100 2
addset set4 2 100 2
