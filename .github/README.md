# 🐧 Gentoo Maintenance

---

## 1. System Updates
Always sync the repositories before updating to ensure you have the latest ebuilds.

```bash
# Sync all repos (Gentoo + GURU + Overlays)
doas emaint sync -a

# Update the entire system
# -u: Update | -D: Deep (check all deps) | -N: NewUse (apply flag changes)
doas emerge --ask --verbose --update --deep --newuse @world

```

## 2. Cleaning Up

Gentoo accumulates "cruft" (old source files and unneeded dependencies) over time.

```bash
# Remove "orphan" dependencies no longer needed
doas emerge --ask --depclean

# Clean out old source tarballs (frees up space in /var/cache/distfiles)
doas eclean --deep distfiles

```

## 3. Managing USE Flags

Flags live in `/etc/portage/package.use/`.

* **To add a flag:** `echo "category/package flag" | doas tee -a /etc/portage/package.use/custom`
* **To find a flag's meaning:** `equery uses <package-name>` (requires `app-portage/gentoolkit`)

## 4. Unmask
* **To unmask a specific package:** `echo "media-sound/rmpc ~amd64" | doas tee -a /etc/portage/package.accept_keywords/custom`
* **To unmask a specific version only:** `echo "=category/package-name-1.2.3 ~amd64" | doas tee -a /etc/portage/package.accept_keywords/custom`

## 5. Fixing Configuration Files

When you update a package, Gentoo protects your custom configs by creating `._cfg0000_filename` files instead of overwriting yours.

```bash
# Check for and interactively merge configuration changes
doas dispatch-conf

```

* **u:** Update (overwrites your config with the new one).
* **z:** Zap (deletes the new config and keeps yours).
* **m:** Merge (interactively choose line-by-line).

## 6. Troubleshooting & Repair

If `emerge` complains about "Slot Conflicts" or "Circular Dependencies":

* **Increase Backtracking:** `doas emerge --ask --update --deep --newuse --backtrack=30 @world`
* **Preserved Libs:** If an update breaks a library dependency, run: `doas emerge @preserved-rebuild`
* **News Items:** Always check these if an update feels "stuck": `eselect news read`
