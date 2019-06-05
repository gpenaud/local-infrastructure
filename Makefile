ONESHELL:

## HELP
PROJECT           = Local LXC Infrastructure Spawner
## Colors
COLOR_RESET       = $(shell tput sgr0)
COLOR_ERROR       = $(shell tput setaf 1)
COLOR_INFO        = $(shell tput setaf 2)
COLOR_COMMENT     = $(shell tput setaf 3)
COLOR_TITLE_BLOCK = $(shell tput setab 4)

## Display this help text
help:
	@printf "\n"
	@printf "${COLOR_TITLE_BLOCK}${PROJECT} Makefile${COLOR_RESET}\n"
	@printf "\n"
	@printf "${COLOR_COMMENT}Usage:${COLOR_RESET}\n"
	@printf " make [target] [backend (optionnal)]\n\n"
	@printf "${COLOR_COMMENT}Available targets:${COLOR_RESET}\n"
	@awk '/^[a-zA-Z\-\_0-9\@]+:/ { \
				helpLine = match(lastLine, /^## (.*)/); \
				helpCommand = substr($$1, 0, index($$1, ":")); \
				helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
				printf " ${COLOR_INFO}%-30s${COLOR_RESET	@sudo /bin/true} %s\n", helpCommand, helpMessage; \
		} \
		{ lastLine = $$0 }' $(MAKEFILE_LIST)
	@printf "\n"

# Validate some parameters presence and sudo
check-and-prepare:
ifndef cluster
$(error cluster MUST be set)
endif
ifeq ("$(wildcard infrastructures/$(cluster)/inventory.yml)","")
$(error cluster definition does not exist)
endif
	@sudo /bin/true

## Build infrastructure without provisionning lxc containers
debug: check-and-prepare
	@ansible-playbook -i infrastructures/$(cluster)/inventory.yml playbooks/debug.yml

## Build infrastructure without provisionning lxc containers
bootstrap: check-and-prepare
	@ansible-playbook -i infrastructures/$(cluster)/inventory.yml playbooks/create.yml --tags bootstrap

## Build infrastructure without provisionning lxc containers
build: check-and-prepare
	@ansible-playbook -i infrastructures/$(cluster)/inventory.yml playbooks/create.yml

## Remove exsiting lxc containers
destroy: check-and-prepare
	@ansible-playbook -i infrastructures/$(cluster)/inventory.yml playbooks/destroy.yml

## Provision previously built lxc containers
provision: check-and-prepare
	@ansible-playbook -i infrastructures/$(cluster)/inventory.yml playbooks/provision.yml

## Destroy, then build lxc containers
rebuild: destroy build

spawn: build provision
respawn: destroy build provision
