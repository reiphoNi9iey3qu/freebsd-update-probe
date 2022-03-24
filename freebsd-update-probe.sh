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


if [ "$#" -ne 0 ] ; then
	cat << EOF_usage
No arguments.  Example usage:
freebsd-update-probe.sh || freebsd-update fetch [install]
  or you could
freebsd-update-probe.sh || mail_sysadmin_to_manually_update
* if /usr/sbin/freebsd-update exit code !=0 be sure to run that manually
  until does exit 0 because the tag assessed by freebsd-update-probe.sh
  is produced by /usr/sbin/freebsd-update
* untested inside FreeBSD Jail environments
* Written/tested on FreeBSD 13.0 (12.2 reported working)
Version: 20220331 ### https://github.com/-------/freebsd-update-probe 
EOF_usage
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

exit_1_clean () {
	rm -rf $TEMPDIR_PROBE
	echo "probe tag file: FAIL, freebsd-update suggested."
	exit 1
}

# Paragraph of freebsd-update origin (renamed + $TEMPDIR_PROBE/.*.probe tweak)
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

probe_tags () {
	if [ -f $TEMPDIR_PROBE/tag.probe -a -f ${FREEBSD_UPDATE_DIR}/tag ] && \
	    cmp -s $TEMPDIR_PROBE/tag.probe ${FREEBSD_UPDATE_DIR}/tag; then
		rm -rf $TEMPDIR_PROBE
		echo "probe tag file: PASS, no freebsd-update needed."
		exit 0
	else
		exit_1_clean
	fi
}

# Nice to group things with regard to their purpose, it could easily
# be a script without using functions.
obtain_tags
probe_tags

