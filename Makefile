VERSION = 3.1.1

prefix = /usr/local
bindir = $(prefix)/bin
mandir = $(prefix)/share/man/man1

SEVENZIP = 7z a -mx=9 -bd -bso0

all: xasm xasm.html

xasm: source/app.d
	dmd -of$@ -O -release $<

xasm.html: xasm.1.asciidoc
	asciidoc -o - $< | sed -e "s/527bbd;/20a0a0;/" >$@

xasm.1: xasm.1.asciidoc
	a2x -f manpage $<

install: xasm xasm.1
	mkdir -p $(DESTDIR)$(bindir) && install xasm $(DESTDIR)$(bindir)/xasm
	mkdir -p $(DESTDIR)$(mandir) && install -m 644 xasm.1 $(DESTDIR)$(mandir)/xasm.1

uninstall:
	$(RM) $(DESTDIR)$(bindir)/xasm $(DESTDIR)$(mandir)/xasm.1

install-scite: xasm.properties
	mkdir -p $(DESTDIR)$(prefix)/share/scite && install $< $(DESTDIR)$(prefix)/share/scite/xasm.properties

uninstall-scite:
	$(RM) $(DESTDIR)$(prefix)/share/scite/xasm.properties

dist: srcdist ../xasm-$(VERSION)-windows.zip

srcdist: MANIFEST
	$(RM) ../xasm-$(VERSION).tar.gz && /usr/bin/tar -c --numeric-owner --owner=0 --group=0 --mode=644 -T MANIFEST --transform=s,,xasm-$(VERSION)/, | $(SEVENZIP) -tgzip -si ../xasm-$(VERSION).tar.gz

MANIFEST:
	if test -e .git; then (git ls-files | grep -vF .gitignore && echo MANIFEST) | sort | dos2unix >$@ ; fi

../xasm-$(VERSION)-windows.zip: xasm xasm.html xasm.properties
	$(RM) $@ && $(SEVENZIP) -tzip $@ xasm.exe xasm.html xasm.properties

deb:
	debuild -b -us -uc

osx: ../xasm-$(VERSION)-macos.dmg

../xasm-$(VERSION)-macos.dmg: osx/xasm osx/bin
	hdiutil create -volname xasm-$(VERSION)-macos -srcfolder osx -format UDBZ -fs HFS+ -imagekey bzip2-level=3 -ov $@

osx/xasm: source/app.d
	mkdir -p osx && dmd -of$@ -O -release -L-macosx_version_min -L10.6 $< && rm -f osx/xasm.o

osx/bin:
	mkdir -p osx && ln -s /usr/bin $@

clean:
	$(RM) xasm xasm.exe xasm.obj xasm.html xasm.1
	rm -rf osx

.PHONY: all install uninstall install-scite uninstall-scite dist srcdist MANIFEST deb osx clean

.DELETE_ON_ERROR:
