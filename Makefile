SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

PREFIX ?= /usr/local
RESTIC_USER ?= restic
RESTIC_GROUP ?= $(RESTIC_USER)

SCRIPT_SOURCES := $(wildcard scripts/*)
SCRIPT_DESTS := $(patsubst scripts/%,$(PREFIX)/etc/restic-backup-systemd/scripts/%,$(SCRIPT_SOURCES))

SERVICE_SOURCES := $(wildcard systemd/*.service)
SERVICE_DESTS := $(patsubst systemd/%.service,/etc/systemd/system/%.service,$(SERVICE_SOURCES))


TIMER_SOURCES := $(wildcard systemd/*.timer)
TIMER_DESTS := $(patsubst systemd/%.timer,/etc/systemd/system/%.timer,$(TIMER_SOURCES))

.PHONY: install
install: $(SCRIPT_DESTS) $(SERVICE_DESTS) $(TIMER_DESTS)
	systemctl daemon-reload

$(PREFIX)/etc/restic-backup-systemd/scripts/%: scripts/%
	mkdir -p $(@D)
	cp $< $@

/etc/systemd/system/%.service: systemd/%.service
	sed \
		--expression 's;__PREFIX__;$(PREFIX);g' \
		--expression 's;__RESTIC_USER__;$(RESTIC_USER);g' \
		--expression 's;__RESTIC_GROUP__;$(RESTIC_GROUP);g' \
		$< > $@


/etc/systemd/system/%.timer: systemd/%.timer
	cp $< $@

# Helper to easily create a restic user. Do not add this to the install tasks
# above. Many use-cases may want to create this user in another way.
.PHONY: restic-user
restic-user:
	useradd --system --create-home --user-group $(RESTIC_USER)
