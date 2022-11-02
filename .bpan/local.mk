v := 1

IMPORTS := $(shell find .bpan/lib -type f)

dev-import: $(IMPORTS)
.bpan/%: ../bashplus/%
	cp -p $< $@
.bpan/%: ../getopt-bash/%
	cp -p $< $@
.bpan/%: ../ini-bash/%
	cp -p $< $@
.bpan/%: ../test-tap-bash/%
	cp -p $< $@

distclean:: clean
	$(RM) config
	$(RM) -r local/

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
	$(RM) core.*
	$(RM) -r test/bin-pkg-bash/
	$(RM) -r test/bpan-*/
	$(RM) -r test/dir/
	$(RM) -r test/lib-pkg/
	$(RM) -r test/local/
