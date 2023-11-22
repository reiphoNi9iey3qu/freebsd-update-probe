#!/bin/bash

diff <(grep -A99 "^* freebsd-update-probe.sh takes no arguments." README.md | grep -B99 ^Version) <(grep -A99 "^* freebsd-update-probe.sh takes no arguments." freebsd-update-probe.sh | grep -B99 ^Version)

