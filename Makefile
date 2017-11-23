OUT_DIR=bin

all: build force_link

install: build link

build:
	@echo "Building git_deploy in $(shell pwd)"
	@mkdir -p $(OUT_DIR)
	@crystal build -o $(OUT_DIR)/git_deploy src/git_deploy.cr -p --no-debug

run:
	$(OUT_DIR)/git_deploy

clean:
	rm -rf  $(OUT_DIR) .crystal .shards libs lib

link:
	@ln -s `pwd`/bin/git_deploy /usr/local/bin/git_deploy

force_link:
	@echo "Symlinking `pwd`/bin/git_deploy to /usr/local/bin/git_deploy"
	@ln -sf `pwd`/bin/git_deploy /usr/local/bin/git_deploy
