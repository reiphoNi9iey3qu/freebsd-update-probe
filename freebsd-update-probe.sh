#!/bin/sh

# BSD 2-Clause License
# 
# Copyright (c) 2022, https://github.com/------- || ------- @ FreeBSD Forums
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#


# A few sections of this code are from freebsd-update, (c) Colin Percival.
# Denoted in the paragraphs below as "Paragraph of freebsd-update origin"


###############################
### freebsd-update-probe.sh ###
###############################

USER=`/usr/bin/whoami`
if ! [ "$USER" = "root" ]; then
   echo "Notice: Must be run by root"
   exit 1
fi

if [ "$#" -ne 0 ] ; then
	cat << EOF_usage
freebsd-update-probe.sh takes no arguments.
Purpose:
* Efficiently determine update availability.
Usage, initially test for any "Notice" messages: 
# freebsd-update-probe.sh 
Usage, after the initial run (normal usage):
# freebsd-update-probe.sh || freebsd-update fetch [install]
# freebsd-update-probe.sh || mail_sysadmin_to_manually_update
Notes:
* Tested on FreeBSD 13.1, 13.0 (12.2 reported working)
* Not for FreeBSD Jail environments
* Not for non-RELEASE FreeBSD versions
* Not for detecting new RELEASE versions
* When /usr/sbin/freebsd-update is run you *must* ensure it completes
  successfully (exit 0) as freebsd-update-probe.sh relies on it.
Version: 20220617 ### https://github.com/-------/freebsd-update-probe 
EOF_usage
	exit 1
fi

if ! [ `freebsd-version | grep '\-RELEASE' | wc -l` = 1 ]; then
	echo "Notice: freebsd-update-probe.sh \"compatability\":"
	echo "Notice: `freebsd-version` is not a RELEASE version."
	echo "Note: Feel free to edit this script and proceed but you're on your own."
	exit 1
fi

# Paragraph of freebsd-update origin
# Generate release number.  The s/SECURITY/RELEASE/ bit exists
# to provide an upgrade path for FreeBSD Update 1.x users, since
# the kernels provided by FreeBSD Update 1.x are always labelled
# as X.Y-SECURITY.
RELNUM=`uname -r |
    sed -E 's,-p[0-9]+,,' |
    sed -E 's,-SECURITY,-RELEASE,'`
ARCH=`uname -m`
FETCHDIR=${RELNUM}/${ARCH}

TEMPDIR_PROBE=`mktemp -d`
FREEBSD_UPDATE_DIR="/var/db/freebsd-update"
SERVERNAME=`host -t srv _http._tcp.update.freebsd.org | sort -R | head -1 | awk 'gsub(/.$/,"") {print $NF}'`

# freebsd-update-probe.sh is not trying to reinvent the wheel.
# /usr/sbin/freebsd-update, when run subsequently, will provide its
# diagnostic info *IF* that is necessary.
exit_1_clean () {
	rm -rf $TEMPDIR_PROBE
	echo "probe result: CHECK, freebsd-update suggested."
	exit 1
}

# A fresh install of FreeBSD does not have an initial tag if it has
# not yet run /usr/sbin/freebsd-update fetch [install]
if ! [ -f $FREEBSD_UPDATE_DIR/tag ]; then
		exit_1_clean
fi

# Paragraph of freebsd-update origin (renamed + $TEMPDIR_PROBE/{latest.ssl,tag}.probe tweaks)
obtain_tags () {
	fetch -q http://${SERVERNAME}/${FETCHDIR}/latest.ssl \
	    -o $TEMPDIR_PROBE/latest.ssl.probe || exit_1_clean
	if ! [ -r $TEMPDIR_PROBE/latest.ssl.probe ]; then
		exit_1_clean
	fi
	openssl rsautl -pubin -inkey ${FREEBSD_UPDATE_DIR}/pub.ssl -verify \
		< $TEMPDIR_PROBE/latest.ssl.probe > $TEMPDIR_PROBE/tag.probe || exit_1_clean
	if ! [ `wc -l < $TEMPDIR_PROBE/tag.probe` = 1 ] ||
		! grep -qE \
		"^freebsd-update\|${ARCH}\|${RELNUM}\|[0-9]+\|[0-9a-f]{64}\|[0-9]{10}" \
		$TEMPDIR_PROBE/tag.probe; then
		echo "invalid signature."
		exit_1_clean
	fi
}


# History, near the most relevant code.
# Bug:
#   https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=258863
# History of what I proposed for freebsd-update (same technique):
#   https://reviews.freebsd.org/D32570 
#
# Why "probe"?  Probe the tag file that belongs to /usr/sbin/freebsd-update
probe_tags () {
	if [ -f $TEMPDIR_PROBE/tag.probe -a -f ${FREEBSD_UPDATE_DIR}/tag ] && \
	    cmp -s $TEMPDIR_PROBE/tag.probe ${FREEBSD_UPDATE_DIR}/tag; then
		rm -rf $TEMPDIR_PROBE
		echo "probe result: MATCH, no freebsd-update needed."
		exit 0
	else
		exit_1_clean
	fi
}

# Nice to group things with regard to their purpose, it could easily
# be a script without using functions.
# The only "exit 0" occurs inside probe_tags.
obtain_tags
probe_tags

