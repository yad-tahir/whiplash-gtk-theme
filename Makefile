# GNU make is required to run this file. To install on *BSD, run:
#   gmake PREFIX=/usr/local install

PREFIX ?= /usr
IGNORE ?=
THEMES ?= $(patsubst %/index.theme,%,$(wildcard themes/whiplash*/index.theme))
PKGNAME = -gtk
MAINTAINER = Daniel Ruiz de Alegría <daniel@drasite.com>

# excludes IGNORE from THEMES list
THEMES := $(filter-out $(IGNORE), $(THEMES))

all:

build:
	cd src && ./build.sh

build-sass:
	cd src && ./build.sh --no-assets

install:
	mkdir -p $(DESTDIR)$(PREFIX)/share/themes
	cp -a $(THEMES) $(DESTDIR)$(PREFIX)/share/themes

uninstall:
	-rm -rf $(foreach theme,$(THEMES),$(DESTDIR)$(PREFIX)/share/$(theme))

packages:
	cd src && ./packages-portage.sh

_get_version:
	$(eval VERSION ?= $(shell git show -s --format=%cd --date=format:%Y%m%d HEAD))
	@echo "$(VERSION)"

_get_tag:
	$(eval TAG := $(shell git describe --abbrev=0 --tags))
	@echo $(TAG)

release: _get_version
	$(MAKE) build
	git add ./themes
	git commit -m "Generate themes for milestone $(VERSION)"
	$(MAKE) generate_changelog VERSION=$(VERSION)
	git tag -f $(VERSION)
	git push origin --tags

undo_release: _get_tag
	-git tag -d $(TAG)
	-git push --delete origin $(TAG)

generate_changelog: _get_version _get_tag
	git checkout $(TAG) CHANGELOG
	echo [$(VERSION)] > /tmp/out
	git log --pretty=format:' * %s' $(TAG)..HEAD >> /tmp/out
	echo >> /tmp/out
	echo | cat - CHANGELOG >> /tmp/out
	mv /tmp/out CHANGELOG
	$$EDITOR CHANGELOG
	git commit CHANGELOG -m "Update CHANGELOG version $(VERSION)"
	git push origin master


.PHONY: all build build-sass install uninstall packages _get_version _get_tag release undo_release generate_changelog

# .BEGIN is ignored by GNU make so we can use it as a guard
.BEGIN:
	@head -3 Makefile
	@false
