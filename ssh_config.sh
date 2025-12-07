#!/bin/sh

# SSH multiplexing options to reuse connections
# This reduces connection overhead and avoids SSH server connection limits
SSH_OPTS="-o ControlMaster=auto -o ControlPath=/tmp/ssh-%r@%h:%p -o ControlPersist=10m"
