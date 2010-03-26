#
# Makefile for sos system support tools
#

NAME	= sos
VERSION = $(shell echo `awk '/^Version:/ {print $$2}' sos.spec`)
RELEASE = $(shell echo `awk '/^Release:/ {gsub(/\%.*/,""); print $2}' sos.spec`)
REPO = http://svn.fedorahosted.org/svn/sos
TMPDIR = /tmp/$(NAME)-$(VERSION)

SUBDIRS = po sos sos/plugins
PYFILES = $(wildcard *.py)

all: subdirs

subdirs:
	for d in $(SUBDIRS); do make -C $$d; [ $$? = 0 ] || exit 1 ; done

install: document
	mkdir -p $(DESTDIR)/usr/sbin
	mkdir -p $(DESTDIR)/usr/share/man/man1
	mkdir -p $(DESTDIR)/usr/share/$(NAME)/extras
	@gzip -c man/en/sosreport.1 > sosreport.1.gz
	mkdir -p $(DESTDIR)/usr/share/doc/$(NAME)-$(VERSION)/_sources
	mkdir -p $(DESTDIR)/usr/share/doc/$(NAME)-$(VERSION)/_static
	mkdir -p $(DESTDIR)/etc
	install -m755 sosreport $(DESTDIR)/usr/sbin/sosreport
	install -m755 extras/rh-upload $(DESTDIR)/usr/share/$(NAME)/extras/rh-upload
	install -m644 sosreport.1.gz $(DESTDIR)/usr/share/man/man1/.
	install -m644 LICENSE README README.rh-upload TODO $(DESTDIR)/usr/share/$(NAME)/.
	install -m644 doc/_build/html/*.{html,inv,js} $(DESTDIR)/usr/share/doc/$(NAME)-$(VERSION)/.
	install -m644 doc/_build/html/_sources/* $(DESTDIR)/usr/share/doc/$(NAME)-$(VERSION)/_sources/.
	install -m644 doc/_build/html/_static/* $(DESTDIR)/usr/share/doc/$(NAME)-$(VERSION)/_static/.
	install -m644 $(NAME).conf $(DESTDIR)/etc/$(NAME).conf
	for d in $(SUBDIRS); do make DESTDIR=`cd $(DESTDIR); pwd` -C $$d install; [ $$? = 0 ] || exit 1; done

document:
	make -C $(PWD)/doc html

archive: 
	@rm -rf $(NAME)-$(VERSION).tar.gz
	@rm -rf $(TMPDIR)
	@svn export --force $(PWD) $(TMPDIR)
	@tar Ccvzf /tmp $(NAME)-$(VERSION).tar.gz $(NAME)-$(VERSION)
	@cp $(NAME)-$(VERSION).tar.gz $(shell rpm -E '%_sourcedir')
	@rm -rf $(NAME)-$(VERSION).tar.gz
	@echo "Archive is $(NAME)-$(VERSION).tar.gz"

clean:
	@rm -fv *~ .*~ changenew ChangeLog.old $(NAME)-$(VERSION).tar.gz
	@rm -rfv {dist,build,sos.egg-info}
	@rm -rf MANIFEST
	@rm -rfv $(TMPDIR)
	@for i in `find . -iname *.pyc`; do \
		rm $$i; \
	done; \
	for d in $(SUBDIRS); do make -C $$d clean ; done

rpm: gpgkey
	@$(MAKE) archive
	@rpmbuild -ba sos.spec

gpgkey:
	@echo "Building gpg key"
	@test -f gpgkeys/rhsupport.pub && echo "GPG key already exists." || \
	gpg --batch --gen-key gpgkeys/gpg.template
