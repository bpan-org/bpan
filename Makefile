.PHONY: \
	push \
	status \
	tail \
	restart \
	stop \
	start \
	reset \
	ssh \
	rebuild \
	test \
	tag \
	untag \

SERVER = webhook.bpan.org
SSH = ssh $(SERVER)
EXCLUDE = \
	  --exclude-from=.gitignore \
	  --exclude=.git \
	  --exclude=.gitignore \
	  --exclude=test \

default: help

help:
	@echo ''
	@echo 'Targets:'
	@echo ''
	@echo '  push       — Sync server code and restart'
	@echo '  status     — Show the unicorn processes'
	@echo '  tail       — Tail the server log'
	@echo '  restart    — Restart the BPAN server'
	@echo '  stop       — Stop the BPAN server'
	@echo '  start      — Start the BPAN server'
	@echo '  reset      — Delete the gh-pages dir'
	@echo '  ssh        — ssh into the server directory'
	@echo ''
	@echo '  rebuild    — Rebuild the remote indexes and webpage'
	@echo '  test       — Run the tests locally'
	@echo '  tag        — ???'
	@echo '  untag      — ???'
	@echo ''

push:
	rsync -avzL \
	    $(EXCLUDE) \
	    --include=id_rsa_server ./ \
	    $(SERVER):bpan-org/
	$(SSH) '\
	    sudo rsync -avzL bpan-org/ /var/www/bpan-org/ && \
	    sudo chown -R www-data /var/www/bpan-org/ \
	'

status:
	$(SSH) 'ps aux | grep unicorn'

tail:
	$(SSH) 'tail -f /var/www/bpan-org/log/unicorn.log'

restart:
	$(SSH) 'sudo /var/www/.rbenv/shims/god stop unicorn && \
	    sleep 1 && \
	    sudo /var/www/.rbenv/shims/god start unicorn \
	'

stop:
	$(SSH) 'sudo /var/www/.rbenv/shims/god stop unicorn'

start:
	$(SSH) 'sudo /var/www/.rbenv/shims/god start unicorn'

reset:
	$(SSH) 'sudo rm -fr /var/www/bpan-org/gh-pages'

ssh:
	$(SSH) -t 'cd /var/www/bpan-org; bash'

rebuild:
	curl --request POST http://webhook.bpan.org/rebuild/

test:
	bundle exec ruby test/bpan_test.rb

untag:
	git push origin :tingle
	git tag -d tingle

tag:
	git tag tingle
	git push --tag
