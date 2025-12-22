### RESTORE_GUIDE.md

```markdown
# Cinderace Emergency Restore Guide

**Goal:** Restore the Gentoo Root ("/") partition using the FSArchiver Stage 4 backup.
**Tool Required:** [SystemRescue](https://www.system-rescue.org/) USB or Gentoo LiveGUI USB.

## 1. Boot Live Environment
Boot into the Live USB. Ensure you have network access if you need to look up documentation, though FSArchiver works offline.

## 2. Identify Your Drives
Run `lsblk` to identify:
1.  **The Destination (Root):** The partition you want to overwrite (e.g., `nvme1n1p3`).
2.  **The Source (Backups):** Your Media drive containing the `.fsa` files (e.g., `sda1` or `nvme0n1p1`).

## 3. Mount the Backup Drive
Create a mount point and mount your storage drive:
```bash
mkdir -p /mnt/backup
mount /dev/Media /mnt/backup
# Verify you see the files
ls -l /mnt/backup/Backups/

```

## 4. Run the Restore Command

*Note: FSArchiver will automatically reformat the destination partition to Btrfs and restore the original UUID (`b28734e4...`).*

Replace `YOUR_ROOT_PARTITION` with the actual device identifier found in Step 2 (e.g., `/dev/nvme1n1p3`).

```bash
fsarchiver restfs \
    /mnt/backup/Backups/cinderace-stage4-os-only-YYYY-MM-DD.fsa \
    id=0,dest=/dev/YOUR_ROOT_PARTITION

```

* **id=0**: Selects the first filesystem in the archive (standard).
* **dest=...**: The target partition to wipe and restore.

## 5. Re-Install GRUB (Only if Drive was Replaced)

*If you just corrupted an update, skip this. If you bought a NEW drive, you must reinstall the bootloader.*

1. Mount the restored root: `mount /dev/YOUR_ROOT_PARTITION /mnt/gentoo`
2. Mount the EFI partition: `mount /dev/YOUR_EFI_PARTITION /mnt/gentoo/boot`
3. Bind mount system dirs:
```bash
for i in dev proc sys; do mount --rbind /$i /mnt/gentoo/$i; done

```


4. Chroot: `chroot /mnt/gentoo /bin/bash`
5. Install: `grub-install --target=x86_64-efi --efi-directory=/boot`
6. Update Config: `grub-mkconfig -o /boot/grub/grub.cfg`
7. Exit and Reboot.

## 6. Post-Boot: Restore User Data

Your OS is now restored to the state of the backup. However, your `/home/evan` data was excluded from the Stage 4 to save space.

1. Log in (likely to a TTY or bare desktop).
2. Open Vorta.
3. Connect to your **Data Repository**.
4. Restore your documents/dotfiles to `/home/evan`.
