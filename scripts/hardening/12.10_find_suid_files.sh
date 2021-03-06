#!/bin/bash

#
# harbian audit 7/8/9  Hardening
#

#
# 12.10 Find SUID System Executables (Not Scored)
#
# set -e # One error, it's over, for some user to audit desktop evn  

# One variable unset, it's over
set -u

HARDENING_LEVEL=2

# This function will be called if the script status is on enabled / audit mode
audit () {
    info "Checking if there are suid files"
    RESULT=$(df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' $SUDO_CMD find '{}' -xdev -type f -perm -4000 -print)
    for BINARY in $RESULT; do
        if grep -q $BINARY <<< "$EXCEPTIONS"; then
            debug "$BINARY is confirmed as an exception"
            RESULT=$(grep -wv "$BINARY" <<< $RESULT)
        fi
    done
    if [ ! -z "$RESULT" ]; then
        crit "Some suid files are present"
        FORMATTED_RESULT=$(sed "s/ /\n/g" <<< $RESULT | sort | uniq | tr '\n' ' ')
        crit "$FORMATTED_RESULT"
    else
        ok "No unknown suid files found"
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
	warn "Removing suid on valid binary may seriously harm your system, report only here, need a manual fix."
}

# This function will create the config file for this check with default values
create_config() {
    cat <<EOF
status=disabled
# Put Here your valid suid binaries so that they do not appear during the audit
EXCEPTIONS="/bin/mount /bin/ping /bin/ping6 /bin/su /bin/umount /usr/bin/chfn /usr/bin/chsh /usr/bin/gpasswd /usr/bin/newgrp /usr/bin/passwd /usr/bin/sudo /usr/bin/sudoedit /usr/lib/openssh/ssh-keysign"
EOF
}

# This function will check config parameters required
check_config() {
    # No param for this function
    :
}

# Source Root Dir Parameter
if [ -r /etc/default/cis-hardening ]; then
    . /etc/default/cis-hardening
fi
if [ -z "$CIS_ROOT_DIR" ]; then
     echo "There is no /etc/default/cis-hardening file nor cis-hardening directory in current environment."
     echo "Cannot source CIS_ROOT_DIR variable, aborting."
    exit 128
fi

# Main function, will call the proper functions given the configuration (audit, enabled, disabled)
if [ -r $CIS_ROOT_DIR/lib/main.sh ]; then
    . $CIS_ROOT_DIR/lib/main.sh
else
    echo "Cannot find main.sh, have you correctly defined your root directory? Current value is $CIS_ROOT_DIR in /etc/default/cis-hardening"
    exit 128
fi
