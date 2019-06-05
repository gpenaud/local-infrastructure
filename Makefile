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
	@printf " make cluster=NAME [target]\n\n"
	@printf "${COLOR_COMMENT}Available targets:${COLOR_RESET}\n"
	@awk '/^[a-zA-Z\-\_0-9\@]+:/ { \
				helpLine = match(lastLine, /^## (.*)/); \
				helpCommand = substr($$1, 0, index($$1, ":")); \
				helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
				printf " ${COLOR_INFO}%-20s${COLOR_RESET} %s\n", helpCommand, helpMessage; \
		} \
		{ lastLine = $$0 }' $(MAKEFILE_LIST)
	@printf "\n"



## Apply debug playbook
debug: check-and-prepare
	@ansible-playbook -i infrastructures/$(cluster)/inventory.yml playbooks/debug.yml

## Execute bootstrapping operations (test network, and add sudouser)
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

## Build, then provision lxc containers
spawn: build provision

## Destroy, build then provision lxc containers
respawn: destroy build provision

## Validate some parameters presence and sudo
check-and-prepare:
	ifndef cluster
	$(error the parameter cluster must be set)
	endif

	ifeq ("$(wildcard infrastructures/$(cluster)/inventory.yml)","")
	$(error the cluster definition is not found)
	endif

	@sudo /bin/true
