SHELL := bash

CSS_URL := https://sindresorhus.com/github-markdown-css/github-markdown.css


#------------------------------------------------------------------------------
default:

all: index.html index.css

open: all
	chromium-browser index.html

clean:
	rm -fr body.html index.html

index.html: head.html body.html foot.html
	cat $+ > $@
	rm -f body.*

%.html: %.md
ifeq (,$(shell command -v showdown))
	$(error 'showdown' not installed. 'npm install -g showdown')
endif
	showdown makehtml -i $< -o $@ >/dev/null

body.md: ../doc/bpan.md
	cp $< $@

index.css: force
	curl -s $(CSS_URL) > $@

force:
