-include config.mk

LIQSRCDIR ?= lib
BIN ?= pngquant
BINPREFIX ?= $(DESTDIR)$(PREFIX)/bin
MANPREFIX ?= $(DESTDIR)$(PREFIX)/share/man

OBJS = pngquant.o pngquant_opts.o rwpng.o
COCOA_OBJS = rwpng_cocoa.o

ifeq (1, $(COCOA_READER))
OBJS += $(COCOA_OBJS)
endif

STATICLIB = lib/libimagequant.a
DISTFILES = *.[chm] pngquant.1 Makefile configure README.md INSTALL CHANGELOG COPYRIGHT
TARNAME = pngquant-$(VERSION)
TARFILE = $(TARNAME)-src.tar.gz

LIBDISTFILES = $(LIQSRCDIR)/*.[ch] $(LIQSRCDIR)/COPYRIGHT $(LIQSRCDIR)/README.md $(LIQSRCDIR)/configure $(LIQSRCDIR)/Makefile

TESTBIN = test/test

all: $(BIN)

$(LIQSRCDIR)/config.mk: config.mk
	( cd '$(LIQSRCDIR)'; ./configure $(LIQCONFIGUREFLAGS) )

$(STATICLIB): $(LIQSRCDIR)/config.mk $(LIBDISTFILES)
	$(MAKE) -C '$(LIQSRCDIR)' static

$(OBJS): $(wildcard *.h) config.mk

rwpng_cocoa.o: rwpng_cocoa.m
	$(CC) -Wno-enum-conversion -c $(CFLAGS) -o $@ $< &> /dev/null || clang -Wno-enum-conversion -c -O3 -o $@ $<

$(BIN): $(OBJS) $(STATICLIBDEPS)
	$(CC) $(OBJS) $(CFLAGS) $(LDFLAGS) -o $@

$(TESTBIN): test/test.o $(STATICLIBDEPS)
	$(CC) $(OBJS) $(CFLAGS) $(LDFLAGS) -o $@

test: $(BIN) $(TESTBIN)
	LD_LIBRARY_PATH='$(LIQSRCDIR)' ./test/test.sh ./test $(BIN) $(TESTBIN)

dist: $(TARFILE)

$(TARFILE): $(DISTFILES)
	rm -rf $(TARFILE) $(TARNAME)
	mkdir -p $(TARNAME)/lib
	cp $(DISTFILES) $(TARNAME)
	cp $(LIBDISTFILES) $(TARNAME)/lib
	tar -czf $(TARFILE) --numeric-owner --exclude='._*' $(TARNAME)
	rm -rf $(TARNAME)
	-shasum $(TARFILE)

install: $(BIN) $(BIN).1
	-mkdir -p '$(BINPREFIX)'
	-mkdir -p '$(MANPREFIX)/man1'
	install -m 0755 -p '$(BIN)' '$(BINPREFIX)/$(BIN)'
	install -m 0644 -p '$(BIN).1' '$(MANPREFIX)/man1/'

uninstall:
	rm -f '$(BINPREFIX)/$(BIN)'
	rm -f '$(MANPREFIX)/man1/$(BIN).1'

clean:
	-$(MAKE) -C '$(LIQSRCDIR)' clean
	rm -f '$(BIN)' $(OBJS) $(COCOA_OBJS) $(STATICLIB) $(TARFILE)

distclean: clean
	-$(MAKE) -C '$(LIQSRCDIR)' distclean
	rm -f config.mk pngquant-*-src.tar.gz

config.mk:
ifeq ($(filter %clean %distclean, $(MAKECMDGOALS)), )
	./configure
endif

.PHONY: all clean dist distclean dll install uninstall test staticlib
.DELETE_ON_ERROR:
