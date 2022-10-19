SHELL := bash

CSS_URL := https://sindresorhus.com/github-markdown-css/github-markdown.css

STAGE_REMOTE ?= ingydotnet

DOCS := $(shell cd ../doc && echo bpan-*.md)
DOCS := $(DOCS:%.md=%)

DOCS_HTML := $(DOCS:%=site/doc/%/index.html)

#------------------------------------------------------------------------------
default:
	@printf '%s\n' $(DOCS_HTML)

build: site site/index.html site/index.css $(DOCS_HTML)

stage: push-stage
	chromium-browser https://stage.bpan.org

open: build
	chromium-browser site/index.html

clean:
	rm -fr site

site:
	git worktree add --force $@ gh-pages

push-origin: commit
	git -C site push origin gh-pages

push-stage: commit
	git -C site push $(STAGE_REMOTE) gh-pages

commit: build
	git -C site add .
	git -C site commit -m 'Update site'

site/index.html: ../doc/bpan.md assert-kramdown
	cat src/head.html > $@
	kramdown -i GFM < $< >> $@
	cat src/foot.html >> $@

site/doc/%/index.html: ../doc/%.md force
	mkdir -p $(dir $@)
	cat src/head.html > $@
	kramdown -i GFM < $< >> $@
	cat src/foot.html >> $@

site/index.css: force
	curl -s $(CSS_URL) > $@

assert-kramdown:
ifeq (,$(shell command -v kramdown))
	$(error 'kramdown' not installed.)
endif
ifeq (,$(shell echo foo | kramdown -i GFM 2>/dev/null))
	$(error 'ruby-kramdown-parser-gfm' not installed.)
endif

force:
