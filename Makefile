.PHONY: deploy tail ssh startstop test

SERVER=webhook.bpan.org
SSH=ssh $(SERVER)
EXCLUDE=--exclude-from=.gitignore --exclude=.git* --exclude=test/

deploy:
	rsync -avzL $(EXCLUDE) --include=id_rsa_server ./ $(SERVER):bpan-org/
	$(SSH) 'sudo rsync -avzL bpan-org/ /var/www/bpan-org/ && sudo chown -R www-data /var/www/bpan-org/ && sudo /var/www/.rbenv/shims/god restart unicorn'

tail:
	$(SSH) 'tail -f /var/www/bpan-org/logs/unicorn.log'

ssh:
	$(SSH)

startstop:
	$(SSH) 'sudo /var/www/.rbenv/shims/god stop unicorn && sleep 10 && sudo /var/www/.rbenv/shims/god start unicorn'

test:
	bundle exec ruby test/bpan_test.rb

untag:
	git push origin :tingle ; git tag -d tingle

tag:
	git tag tingle ; git push --tag