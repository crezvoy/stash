PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man
COMPDIR ?= $(PREFIX)/share/bash-completion/completions

all:

install:
	install -d $(BINDIR)
	install -m 0755 src/stash.sh $(BINDIR)/stash
	install -d $(MANDIR)
	install -m 0644 man/stash.1 $(MANDIR)/stash.1
	install -d $(COMPDIR)
	install -m 0644 src/bash_completion $(COMPDIR)/stash
		
tests=$(patsubst t/%.t.sh,%,$(wildcard t/*.t.sh))

check: $(tests)

ifdef (DBG)
$(tests): export DBG := 1
endif

$(tests): %: t/%.t.sh t/common.sh
	$< 

.PHONY: $(tests) all install check test
