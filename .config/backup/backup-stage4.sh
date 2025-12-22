#!/bin/bash

# --- CONFIGURATION ---
# Run 'ls -l /dev/disk/by-uuid/' to find yours
ROOT_DEV="/dev/disk/by-uuid/b28734e4-799a-4434-bc3a-3df6834cd19d"

DEST_DIR="/mnt/Media/Backups"
DATE=$(date +%F)
FILENAME="cinderace-stage4-os-only-$DATE.fsa"

# --- SAFETY CHECKS ---
if [ ! -e "$ROOT_DEV" ]; then
    echo "Error: Root device UUID not found. Check your config."
    exit 1
fi

if ! grep -qs '/mnt/Media' /proc/mounts; then
    echo "Error: Media drive is not mounted."
    exit 1
fi

echo "Starting System-Only Backup (Excluding /home contents)..."

# --- THE BACKUP COMMAND ---
# Explanation of Excludes:
# --exclude="/home/*" : Keeps the /home folder, but drops your personal data (handled by Borg)
# --exclude="/mnt/*"  : Prevents recursion (backing up the backup drive)
# --exclude="/var/tmp/*" : Junk
# --exclude="/var/cache/distfiles/*" : Saves space (Gentoo source files, re-downloadable)

doas fsarchiver savefs -v -j$(nproc) -A -Z 3 \
    --exclude="/home/*" \
    --exclude="/mnt/*" \
    --exclude="/tmp/*" \
    --exclude="/var/tmp/*" \
    --exclude="/var/cache/distfiles/*" \
    "$DEST_DIR/$FILENAME" \
    "$ROOT_DEV"

# --- CLEANUP ---
# Optional: Keep only the 2 most recent Stage 4 files to save space
echo "Pruning old Stage 4 archives..."
ls -t $DEST_DIR/cinderace-stage4-os-only-*.fsa | tail -n +3 | xargs -I {} rm -- {}

echo "System Snapshot Complete: $FILENAME"
