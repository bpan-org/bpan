.PHONY: deploy tail ssh startstop

SERVER=webhook.bpan.org
SSH=ssh $(SERVER)
EXCLUDE=--exclude-from=.gitignore --exclude=.git*

deploy:
	rsync -avzL $(EXCLUDE) --include=id_rsa_server ./ $(SERVER):bpan-org/
	$(SSH) 'sudo rsync -avzL bpan-org/ /var/www/bpan-org/ && sudo chown -R www-data /var/www/bpan-org/ && sudo /var/www/.rbenv/shims/god restart unicorn'

tail:
	$(SSH) 'tail -f /var/www/bpan-org/logs/unicorn.log'

ssh:
	$(SSH)

startstop:
	$(SSH) 'sudo /var/www/.rbenv/shims/god stop unicorn && sleep 10 && sudo /var/www/.rbenv/shims/god start unicorn'
