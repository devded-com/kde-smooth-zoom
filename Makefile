SHELL := /bin/bash

NAME    := com.devded.kde-smooth-zoom
VERSION := 1.0.0
DIST    := dist
PKG     := $(DIST)/pkg

.PHONY: all sync applet check install uninstall release clean

all: applet

sync:
	@./scripts/sync-applet.sh

applet: sync
	@rm -rf "$(PKG)"
	@mkdir -p "$(PKG)"
	@cp -a plasma/applet/. "$(PKG)/"
	@cp LICENSE "$(PKG)/LICENSE"
	@cd "$(PKG)" && zip -qr "../$(NAME).plasmoid" .
	@echo "built $(DIST)/$(NAME).plasmoid"

check: sync
	@bash -n bin/smooth-zoom
	@bash -n install.sh
	@bash -n scripts/sync-applet.sh
	@test -x bin/smooth-zoom
	@cmp -s bin/smooth-zoom plasma/applet/contents/code/smooth-zoom || \
		{ echo "applet helper is out of sync; run make sync"; exit 1; }
	@qmllint plasma/applet/contents/ui/main.qml
	@echo "checks passed"

install: applet
	@./install.sh

uninstall:
	@./install.sh --uninstall

release: applet
	@sha256sum "$(DIST)/$(NAME).plasmoid" | tee "$(DIST)/SHA256SUMS"
	@echo "release files are in $(DIST)/"

clean:
	@rm -rf "$(DIST)"
