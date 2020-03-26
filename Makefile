.PHONY: setup
setup:
	find .git/hooks -type l -exec rm {} \;\
	&& find config/git-hooks -type f -exec ln -sf ../../{} .git/hooks/ \;

