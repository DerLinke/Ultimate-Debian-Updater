prefix = /usr
bindir = $(prefix)/bin

install:
	install -Dm755 update.sh $(DESTDIR)$(bindir)/update
