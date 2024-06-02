# vm-snapshot.sh
A simple script that will attempt to perform an incremental backup on a given 
VM (or VMs).  This script is not a replacement for real enterprise grade 
solutions.  This script is what I use as a part of my own personal backup
needs as a software dev.

## Dependencies
You will need `virsh` (https://www.libvirt.org/manpages/virsh.html) and 
`virtnbdbackup` (https://github.com/abbbi/virtnbdbackup) installed in order
 to perform a snapshot.  Getting these installed for your system is out of 
scope for this document.

## Usage
The script has two paramaters;
 1. `-d`, used to specify what VMs to backup.  Multiple VMs may be passed to
    the script as a comma seperated list (vm1,vm2,vm3).  You may also pass in
    "*" (with double-quotes) and all VMs found on the system will be backed up.
 2. `-o`, the output directory.  Only the root of the backup directory needs to
    be included, the script will generate the rest.
 3. `-p`, prune last months backups if it's the 15th or later in the month.

### Sample usages
Backup a single VM.
```
./vm-snapshot.sh -d vm1 -o /tmp/backup 
```

Next, backup a set of VMs.
```
./vm-snapshot.sh -d vm1,vm2,vm6 -o /tmp/backup 
```

Finally, backup all VMs found on the system.  Use with caution.

```
./vm-snapshot.sh -d "*" -o /tmp/backup 
```
