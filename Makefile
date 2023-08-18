SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# User name and group of system user executing restig.
RESTIC_USER ?= restic
RESTIC_GROUP ?= $(RESTIC_USER)

# Directory containing the configurations (as sub directories) for the
# individual systemd units.
CONFIG_DIR ?= /etc/restic-systemd-backup

# Directory this repository was checked out to. All scripts remain in this
# directory. They do not need to be on the path. Only the systemd units need
# to be copied elsewhere
REPO_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# Destination directory for systemd units.
SYSTEMD_UNIT_DIR ?= /etc/systemd/system


TEMPLATE_VARS := RESTIC_USER RESTIC_GROUP REPO_DIR CONFIG_DIR
export $(TEMPLATE_VARS)

BASH_DIR := bash
BUILD_DIR := build

SYSTEMD_SRC_DIR := systemd
SYSTEMD_BUILD_DIR := $(BUILD_DIR)/systemd
SYSTEMD_SERVICE_SRCS := $(wildcard $(SYSTEMD_SRC_DIR)/*.service)
SYSTEMD_SERVICE_BUILDS := $(patsubst $(SYSTEMD_SRC_DIR)/%,$(SYSTEMD_BUILD_DIR)/%,$(SYSTEMD_SERVICE_SRCS))
SYSTEMD_TIMER_SRCS := $(wildcard $(SYSTEMD_SRC_DIR)/*.timer)
SYSTEMD_TIMER_BUILDS := $(patsubst $(SYSTEMD_SRC_DIR)/%,$(SYSTEMD_BUILD_DIR)/%,$(SYSTEMD_TIMER_SRCS))

SYSTEMD_BUILDS := $(SYSTEMD_SERVICE_BUILDS) $(SYSTEMD_TIMER_BUILDS)
SYSTEMD_UNITS_INSTALLED := $(patsubst $(SYSTEMD_BUILD_DIR)/%,$(SYSTEMD_UNIT_DIR)/%,$(SYSTEMD_BUILDS))


.DEFAULT_GOAL := $(BUILD_DIR)

$(BUILD_DIR): $(SYSTEMD_BUILDS)

.PHONY: install
install: $(SYSTEMD_UNITS_INSTALLED)
	systemctl daemon-reload


$(SYSTEMD_BUILDS): $(SYSTEMD_BUILD_DIR)/%: $(SYSTEMD_SRC_DIR)/%
	mkdir -p $(@D)
	envsubst '$(patsubst %,$$%,$(TEMPLATE_VARS))' <$< >$@

$(SYSTEMD_UNITS_INSTALLED): $(SYSTEMD_UNIT_DIR)/%: $(SYSTEMD_BUILD_DIR)/%
	cp $< $@
