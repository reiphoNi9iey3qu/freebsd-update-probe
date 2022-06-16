# freebsd-update-probe.sh

### Efficiently detect updates for /usr/sbin/freebsd-update

### Summary
```
freebsd-update-probe.sh efficiently assesses the necessity of subsequently
running: /usr/sbin/freebsd-update fetch [install] 

The IO intensive phase of /usr/sbin/freebsd-update should be reserved
for when updates are available and freebsd-update-probe.sh was created
to achieve this.

freebsd-update-probe.sh was originally pushed to GitHub March 24 2022,
there have been a few minor improvements since.

freebsd-update-probe.sh provides a work around for FreeBSD bug:
  https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=258863
```

### Additional reading
```
Confirmation of a lack of updates is confirmed hundreds of time faster on
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

# Usage
```
freebsd-update-probe.sh takes no arguments.
Purpose:
* Efficiently determine update availability.
Example usage:
# freebsd-update-probe.sh || freebsd-update fetch [install]
# freebsd-update-probe.sh || mail_sysadmin_to_manually_update
Notes:
* Tested on FreeBSD 13.1, 13.0 (12.2 reported working)
* Not for FreeBSD Jail environments
* Not for non-RELEASE FreeBSD versions
* Not for detecting new RELEASE versions
* When /usr/sbin/freebsd-update is run you *must* ensure it completes
  successfully (exit 0) as freebsd-update-probe.sh relies on it.
Version: 20220616 ### https://github.com/-------/freebsd-update-probe 
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

# Demonstration #1 with Slow IO. 
## Raspberry Pi 3B:  1m32s down to sub 1s.
### Before (Raspberry Pi 3B): 1m32s
```
# date ; time freebsd-update fetch install ; date
Sat Mar 26 08:41:00 NZDT 2022
src component not installed, skipped
Looking up update.FreeBSD.org mirrors... 2 mirrors found.
Fetching metadata signature for 13.0-RELEASE from update1.freebsd.org... done.
Fetching metadata index... done.
Inspecting system... done.
Preparing to download files... done.

No updates needed to update system to 13.0-RELEASE-p10.
No updates are available to install.
76.646u 22.863s 1:32.08 108.0%  22+170k 0+0io 0pf+0w
Sat Mar 26 08:42:32 NZDT 2022
```

### After (Raspberry Pi 3B): sub 1s
```
# date ; time /root/freebsd-update-probe.sh || freebsd-update fetch install ; date
Sat Mar 26 08:43:48 NZDT 2022
probe tag file: MATCH, no freebsd-update needed.
0.095u 0.103s 0:00.51 37.2%     96+171k 0+0io 0pf+0w
Sat Mar 26 08:43:48 NZDT 2022
```


# Demonstration #2 with Fast IO. 
## SSD backed VM.  ~11s down to sub 1s
### Before (SSD backed VM): ~11s
```
root@-------:~ # /usr/bin/time freebsd-update fetch install
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
root@-------:~ # /usr/bin/time freebsd-update-probe.sh || /usr/bin/time freebsd-update fetch install
probe tag file: MATCH, no freebsd-update needed.
        0.40 real         0.04 user         0.02 sys
```


# Important
```
This is not only a reduction in time, freebsd-update-probe.sh bypasses
the processing and IO spike that would otherwise occur for that duration
within `/usr/sbin/freebsd-update fetch [install]`

Finally, I hope you find freebsd-update-probe.sh useful.
```
