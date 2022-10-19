SITE_ALL := \
    build \
    open \
    stage \
    site \
    push-origin \
    push-stage \
    clean \

SITE_ALL := $(SITE_ALL:%=site-%)

$(SITE_ALL)::
	$(MAKE) -C www $(@:site-%=%)

distclean::
	rm -f config
	rm -fr local/
	rm -fr test/bpan/
	rm -fr test/bin-pkg-bash/
	rm -fr test/lib-pkg/
