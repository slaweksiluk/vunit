#!/bin/bash
set -e
rm -f wrpipe* rdpipe*
mknod wrpipe0 p
mknod rdpipe0 p
