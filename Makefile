PACKAGE=lua-uri
VERSION=$(shell head -1 Changes | sed 's/ .*//')
RELEASEDATE=$(shell head -1 Changes | sed 's/.* //')
PREFIX=/usr/local
DISTNAME=$(PACKAGE)-$(VERSION)

# The path to where the module's source files should be installed.
LUA_SPATH:=$(shell pkg-config lua5.1 --define-variable=prefix=$(PREFIX) \
                              --variable=INSTALL_LMOD)

MANPAGES = doc/lua-uri.3 doc/lua-uri-_login.3 doc/lua-uri-_util.3 doc/lua-uri-data.3 doc/lua-uri-file.3 doc/lua-uri-ftp.3 doc/lua-uri-http.3 doc/lua-uri-pop.3 doc/lua-uri-rtsp.3 doc/lua-uri-telnet.3 doc/lua-uri-urn.3 doc/lua-uri-urn-isbn.3 doc/lua-uri-urn-issn.3 doc/lua-uri-urn-oid.3

all: $(MANPAGES)

doc/lua-%.3: doc/lua-%.pod
	sed 's/E<copy>/(c)/g' <$< | sed 's/E<ndash>/-/g' | \
	    pod2man --center="Lua $(shell echo $< | sed 's/^doc\/lua-//' | sed 's/\.pod$$//' | sed 's/-/./g') module" \
	            --name="$(shell echo $< | sed 's/^doc\///' | sed 's/\.pod$$//' | tr a-z A-Z)" --section=3 \
	            --release="$(VERSION)" --date="$(RELEASEDATE)" >$@

test: all
	for f in test/*.lua; do lua $$f; done

install: all
	mkdir -p $(LUA_SPATH)/uri/{file,urn}
	mkdir -p $(PREFIX)/share/man/man3
	install --mode=644 uri.lua $(LUA_SPATH)/
	for module in _login _relative _util data file ftp http https pop rtsp rtspu telnet urn; do \
	    install --mode=644 uri/$$module.lua $(LUA_SPATH)/uri/; \
	done
	for module in unix win32; do \
	    install --mode=644 uri/file/$$module.lua $(LUA_SPATH)/uri/file/; \
	done
	for module in isbn issn oid; do \
	    install --mode=644 uri/urn/$$module.lua $(LUA_SPATH)/uri/urn/; \
	done
	for manpage in $(MANPAGES); do \
	    gzip -c $$manpage >$(PREFIX)/share/man/man3/$$(echo $$manpage | sed -e 's/^doc\///').gz; \
	done

checktmp:
	@if [ -e tmp ]; then \
	    echo "Can't proceed if file 'tmp' exists"; \
	    false; \
	fi
dist: all checktmp
	mkdir -p tmp/$(DISTNAME)
	tar cf - --files-from MANIFEST | (cd tmp/$(DISTNAME) && tar xf -)
	cd tmp && tar cf - $(DISTNAME) | gzip -9 >../$(DISTNAME).tar.gz
	cd tmp && tar cf - $(DISTNAME) | bzip2 -9 >../$(DISTNAME).tar.bz2
	rm -f $(DISTNAME).zip
	cd tmp && zip -q -r -9 ../$(DISTNAME).zip $(DISTNAME)
	rm -rf tmp

clean:
	rm -f $(MANPAGES)

.PHONY: all test install checktmp dist clean
