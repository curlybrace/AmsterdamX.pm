all: build

build:
	bash bin/create.sh

announce:
	bash bin/announce.pl

.PHONY: build

