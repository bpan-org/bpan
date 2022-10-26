FROM ingy/bash-testing:0.1.0

RUN apt-get update \
 && apt-get install -y \
        ash \
        cpio \
        curl \
        dash \
        fish \
        iputils-ping \
        ksh \
        mksh \
        pandoc \
        posh \
        yash \
        zsh \
 && true

RUN git config --global --add safe.directory /host \
 && git config --global --add safe.directory \
        /host/local/src/github/bpan-org/bpan-index \
 && true
