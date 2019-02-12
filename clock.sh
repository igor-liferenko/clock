#!/bin/sh
while [ 1 ]; do
  2>&- date +%T >/dev/ttyACM0
  sleep 1
done
