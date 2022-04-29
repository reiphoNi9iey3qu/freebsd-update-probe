#!/bin/bash

diff <(grep -A99 ^No\ arguments README.md | grep -B99 ^Version) <(grep -A99 ^No\ arguments freebsd-update-probe.sh | grep -B99 ^Version)

