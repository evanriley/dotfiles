# Building/Flashing my keyboard configs.

- Install the QMK cli and run
```
qmk setup -H ~/.config/keyboards/qmk
```

- Symlink keymap with make
```
make link
```

-  Build with make
```
make build 
```

- Flash with cli or QMK Toolbox
```
make flash
```

#### Current (known) issues

- Makefile currently only supports 1 keymap (planck)
- `make clean` doesn't cleanup .bin files in qmk directory
- The 'arm-gcc-bin' sometimes just doesn't seem to be on my path run the following command to fix
```
fish_add_path /opt/homebrew/opt/arm-gcc-bin@8/bin
```

