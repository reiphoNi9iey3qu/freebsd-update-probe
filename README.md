# freebsd-update-probe.sh

## Efficiently detect updates for /usr/sbin/freebsd-update

### Summary
```
freebsd-update-probe.sh efficiently assesses the necessity of subsequently
running: /usr/sbin/freebsd-update fetch [install] 

The IO intensive phase of /usr/sbin/freebsd-update should be reserved
for when updates are available and freebsd-update-probe.sh was created
to achieve this.

This is not only a reduction in time, freebsd-update-probe.sh bypasses
the processing and IO spike that would otherwise occur for that duration
within `/usr/sbin/freebsd-update fetch [install]` , when no updates are
available it only makes sense to avoid this.

freebsd-update-probe.sh provides a work around for FreeBSD bug:
  https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=258863

freebsd-update-probe.sh was originally pushed to GitHub March 24 2022,
there have been a few minor improvements since.

Finally, I hope you find freebsd-update-probe.sh useful.
```

# Usage
```
Purpose:
* Efficiently determine update availability.
Usage:
# freebsd-update-probe.sh || freebsd-update fetch [install]
# freebsd-update-probe.sh || mail_sysadmin_to_manually_update
Notes:
* freebsd-update-probe.sh takes no arguments.
* If you see "Notice" messages, attend to those.
* When /usr/sbin/freebsd-update is run you *must* ensure it completes
  successfully (exit 0) as freebsd-update-probe.sh relies on it.
* Not for detecting new RELEASE versions
* Not for non-RELEASE FreeBSD versions
* Not for FreeBSD Jail environments
* Tested on FreeBSD 13.1, 13.0 (12.3, 12.2 reported working)
Version: 20221101 ### https://github.com/-------/freebsd-update-probe 
```

# Exit codes
```
exit 0, MATCH, no freebsd-update needed.
exit 1, CHECK, freebsd-update suggested.
```

# Deploy examples
```
fetch https://raw.githubusercontent.com/-------/freebsd-update-probe/main/freebsd-update-probe.sh -o /usr/local/bin/freebsd-update-probe.sh
chmod 700 /usr/local/bin/freebsd-update-probe.sh
# Or
fetch https://raw.githubusercontent.com/-------/freebsd-update-probe/main/freebsd-update-probe.sh -o freebsd-update-probe.sh
scp freebsd-update-probe.sh root@server.example.com:/usr/local/bin/
ssh root@server.example.com "chmod 700 /usr/local/bin/freebsd-update-probe.sh"
```

# Additional reading & Demonstrations
```
Confirmation of a lack of updates is reached hundreds of time faster on
Raspberry Pi 3B using freebsd-update-probe.sh, this is demonstrated below
(before/after).  IO bound hardware benefits greatly, results are far less
dramatic for fast IO but the reduction of unnecessary activity is gained.

freebsd-update-probe.sh tests for a match between the current "tag" and
the upstream "tag", /usr/sbin/freebsd-update generates the "tag" that is
stored on disk and the "tag" from /usr/sbin/freebsd-update is authoritive.
This "tag" file is probed by freebsd-update-probe.sh, hence the name.

Strictly speaking the updates mention above are point level updates.
freebsd-update-probe.sh has no knowledge of a new RELEASE, which is also
true for `/usr/sbin/freebsd-update fetch [install]`,  When a new RELEASE
version is available it must be manually installed, updating to a new
RELEASE is a distinct and deliberate action.
   https://docs.freebsd.org/en/books/handbook/ (search "update")
```

## Demo #1 with Slow IO. 
### Before (Raspberry Pi 3B): ~3m20s
```
# /usr/bin/time freebsd-update fetch install
src component not installed, skipped
Looking up update.FreeBSD.org mirrors... 2 mirrors found.
Fetching metadata signature for 13.1-RELEASE from update2.freebsd.org... done.
Fetching metadata index... done.
Inspecting system... done.
Preparing to download files... done.

No updates needed to update system to 13.1-RELEASE-p1.
No updates are available to install.
      200.64 real       199.41 user         3.20 sys
```

### After (Raspberry Pi 3B): sub 1s
```
# /usr/bin/time freebsd-update-probe.sh || /usr/bin/time freebsd-update fetch install
probe result: MATCH, no freebsd-update needed.
        0.51 real         0.08 user         0.14 sys
```


## Demo #2 with Fast IO. 
### Before (SSD backed VM): ~11s
```
# /usr/bin/time freebsd-update fetch install
src component not installed, skipped
Looking up update.FreeBSD.org mirrors... 2 mirrors found.
Fetching metadata signature for 13.1-RELEASE from update2.freebsd.org... done.
Fetching metadata index... done.
Inspecting system... done.
Preparing to download files... done.

No updates needed to update system to 13.1-RELEASE-p0.
No updates are available to install.
       10.89 real        10.04 user         0.37 sys
```

### After (SSD backed VM): sub 1s
```
# /usr/bin/time freebsd-update-probe.sh || /usr/bin/time freebsd-update fetch install
probe tag file: MATCH, no freebsd-update needed.
        0.40 real         0.04 user         0.02 sys
```

