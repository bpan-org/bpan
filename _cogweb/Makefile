.PHONY: \
	site \
	up \

SITE = ..

default: help

help:
	@echo ''
	@echo 'Targets:'
	@echo ''
	@echo '  site       — Rebuild site'
	@echo '  up         — Upgrade the cogwebs site'
	@echo ''

site:
	./bin/site.rb $(SITE)

up:
	git pull --rebase
