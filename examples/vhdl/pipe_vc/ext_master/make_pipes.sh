#!/bin/bash
set -e
rm -f *wrpipe *rdpipe
mknod master0_wrpipe p
mknod master0_rdpipe p
mknod master1_wrpipe p
mknod master1_rdpipe p
