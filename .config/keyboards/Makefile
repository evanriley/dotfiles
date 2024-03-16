KEYMAP_DIR=qmk/keyboards/planck/keymaps/evanriley

.PHONY: build
build: link
	qmk compile -kb planck/rev6 -km evanriley

.PHONY: flash
flash: link
# flash command also automatically builds
	qmk flash -kb planck/rev6 -km evanriley

.PHONY: link
link: unlink
	ln -sf "$(realpath planck)" "${KEYMAP_DIR}"

.PHONY: unlink
unlink:
	rm -rf  "${KEYMAP_DIR}"

.PHONY: clean
clean: unlink
	qmk clean

