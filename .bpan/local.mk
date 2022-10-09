distclean::
	rm -f config
	rm -fr local/
	rm -fr test/bpan/
	rm -fr test/bin-pkg-bash/
	rm -fr test/lib-pkg/

gh-pages::
	git worktree add --force $@ $@

clean::
	rm -f .bpan/pid-*
