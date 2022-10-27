distclean::
	rm -f config
	rm -fr local/
	rm -fr test/bpan/
	rm -fr test/bin-pkg-bash/
	rm -fr test/lib-pkg/

gh-pages::
	git worktree add --force $@ $@


DOCKER_IMAGE := ingy/bpan-testing:0.1.0
BASH_HISTORY := /tmp/bpan-test-docker-bash-history

test-3.2: test-docker-build
	bpan test --verbose --bash=3.2 $(test)

test-docker-shell: test-docker-build
	touch $(BASH_HISTORY)
	docker run --rm -it \
	    -v $(shell pwd):/host \
	    -v $(SSH_AUTH_SOCK):$(SSH_AUTH_SOCK) \
	    -v $(BASH_HISTORY):/root/.bash_history \
	    -v $(HOME)/.ssh/known_hosts:/root/.ssh/known_hosts \
	    -w /host \
	    -e SSH_AUTH_SOCK=$(SSH_AUTH_SOCK) \
	    $(DOCKER_IMAGE) \
	        bash

test-docker-build:
	docker build \
	    -t $(DOCKER_IMAGE) \
	    -f test/Dockerfile \
	    .

test-docker-push: test-docker-build
	docker push $(DOCKER_IMAGE)

clean:
	rm -fr test/bpan-* test/local
