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
	rm -f body.html

%.html: %.md
	showdown makehtml -i $< -o $@ >/dev/null

index.css: force
	curl -s $(CSS_URL) > $@

force:
