#!/bin/sh

is_debug() {
    [ "$BLUBEE_DEBUG" = "true" ]
}

debug_echo() {
    if is_debug; then
        echo "DEBUG: $@"
    fi
}
