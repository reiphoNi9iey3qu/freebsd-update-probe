#!/bin/bash

diff <(cat README.md | grep -A99 ^No\ arguments | grep -B99 ^Version) <(cat freebsd-update-probe.sh | grep -A99 ^No\ arguments | grep -B99 ^Version)

