#!/usr/bin/env bash
#
# vm-snapshot.sh
# Copyright (C) 2024  Sentry0
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
# 
# ---
#
# Will perform an incremental backup (if possible) of a running or stopped VM 
# and deposit it into a monthly backup directory.  On the 15th of the current 
# month, the previous month's snapshots are deleted. This means there will be 
# about 2-6 weeks of backups at any given time.

# Creates a lock so that only one instance of this script may be executed
[ "${FLOCKER}" != "$0" ] && exec env FLOCKER="$0" flock -xn "$0" "$0" "$@" || :

BACKUP_TOOL=`which virtnbdbackup`

VIRSH=`which virsh`

if [ -z "${VIRSH}" ]; then
    printf "Could not find virsh.\n"

    exit 1
fi

if [ -z "${BACKUP_TOOL}" ]; then
    printf "Could not find virtnbdbackup.\n\n"
    printf "https://github.com/abbbi/virtnbdbackup\n"

    exit 99
fi

print_help () {
    printf "Performs an incremental backup (if possible) on the given VMs.\n\n"
    printf "Usage:\n  -d [VM_NAME(S) or \"*\"]\n  -o [PATH]\n\n"
    printf "Example: vm-snapshot -d vm1,vm2,vm3 -o /tmp/backups\n"
}

BACKUP_DIR=""

while getopts ':d:o:h' OPTION; do
    case "${OPTION}" in    
        d)
	    VM_LIST="${OPTARG}"
	    
	    if [ "${VM_LIST}" = "*" ]; then
		VM_LIST=`${VIRSH} list --all --name | /usr/bin/paste -sd "," -`
            fi

	    IFS=',' read -r -a VMs <<< "${VM_LIST}"
        ;;
        o) 
            BACKUP_DIR=${OPTARG}
        ;;
	h|\?)
            print_help

	    exit 0
	;;
    esac
done

shift "$(($OPTIND -1))"

if [ ${#VMs[@]} -eq 0 ] || [ ! -d ${BACKUP_DIR}  ]; then
    printf "Please supply at least one VM name and an output dir "
    printf "(vm-snapshot -d vm1 -o /tmp/backups).\n\n"
    printf "Multiple VMs may be passed with commas (-d vm1,vm2,etc...).  "
    printf "Use \"*\" (with quotes) to select all VMs.\n"

    exit 100
fi

DAY_OF_MONTH=`date +'%d'`

SNAPSHOT_NAME=`date +'%Y-%m'`

# Backup all the VMs, running or stopped, incrementally if possible
for name in ${VMs[@]}; do
    ${VIRSH} domstate ${name} > /dev/null 2>&1

    if [ $? -ne 0 ]; then
	printf "WARNING: Could not find a VM named \"${name}\"\n"
    
        continue
    fi

    SNAPSHOT_PATH=${BACKUP_DIR}/${name}/${SNAPSHOT_NAME}

    printf "Backing up ${name} to ${SNAPSHOT_PATH}\n"
   
    ${BACKUP_TOOL} -S --noprogress -d ${name} -l auto -o ${SNAPSHOT_PATH}

    # Delete last month's backups if our latest backup succeeded and it is the
    # middle of the current month.
    if [ $? -eq 0 ] && [ ${DAY_OF_MONTH} -eq 15 ]; then
        LAST_MONTH=`date -d "$(date +%Y-%m-1) -1 month" +%Y-%m`
    
    	LAST_MONTHS_BACKUPS_DIR=${BACKUP_DIR}/${name}/${LAST_MONTH}

        if [ -d ${LAST_MONTHS_BACKUPS_DIR} ]; then
            printf "Removing backups for ${name} for ${LAST_MONTH}\n"
	
            rm -rf ${LAST_MONTHS_BACKUPS_DIR}
        fi
    fi
done

exit 0
