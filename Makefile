SERVER=webhook.bpan.org
EXCLUDE=--exclude-from=.gitignore --exclude=.git*

deploy: 
	rsync -avzL $(EXCLUDE) --include=id_rsa_server ./ $(SERVER):bpan-org/
	ssh $(SERVER) 'sudo rsync -avzL bpan-org/ /var/www/bpan-org/ && sudo chown -R www-data /var/www/bpan-org/' 

tail:
	ssh $(SERVER) 'tail -f /var/www/bpan-org/logs/unicorn.log'

ssh:
	ssh $(SERVER)
