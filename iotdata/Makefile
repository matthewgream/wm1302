
# iotdata packaging for the wm1302 (sx1302_hal) LoRaWAN packet forwarder.
#
# Deliberately separate from the upstream tree's own Makefile: this is a submodule tracking an
# upstream project, so anything added to its build files collides on every update. Everything
# iotdata-specific lives in this directory instead, and is driven by `make install` at the
# iotdata-depend top level, which invokes the install target of any <submodule>/iotdata/Makefile.
#
# Upstream builds packet_forwarder/lora_pkt_fwd; iotdata installs it as `lorawan2ttn`, which is
# already the name it logs under.

DIR_UPSTREAM=..
BUILD=$(DIR_UPSTREAM)/packet_forwarder/lora_pkt_fwd

INSTALL=lorawan2ttn
DIR_INSTALL=/usr/local/bin
DIR_CONFIG=/etc/$(INSTALL)
DIR_SYSTEMD=/etc/systemd/system
DIR_UDEV=/etc/udev/rules.d

# Prefer a per-host config (global_conf.<hostname>.json) over the shared default, matching the
# convention used by hostmon, connmon and the iotdata gateway.
HOSTNAME:=$(shell hostname)
CFG_SRC:=$(if $(wildcard global_conf.$(HOSTNAME).json),global_conf.$(HOSTNAME).json,global_conf.json)

# This forwarder predates the packaging and ran as lora-pkt-fwd.service straight out of the build
# directory. That unit is retired on install: left enabled, both would contend for /dev/wm1302.
LEGACY=lora-pkt-fwd

##

# Building stays with upstream's Makefile — refuse clearly rather than silently invoking it.
install_target:
	@test -x $(BUILD) || { echo "$(BUILD) is not built: run 'make' in $(DIR_UPSTREAM) first"; exit 1; }
	install -m 755 $(BUILD) $(DIR_INSTALL)/$(INSTALL)
install_config: $(CFG_SRC)
	@echo "installing config from $(CFG_SRC)"
	install -d -m 755 $(DIR_CONFIG)
	install -m 644 $(CFG_SRC) $(DIR_CONFIG)/global_conf.json
install_udev: 90-wm1302.rules
	install -m 644 90-wm1302.rules $(DIR_UDEV)/90-wm1302.rules
	udevadm control --reload
	udevadm trigger
install_service: $(INSTALL).service
	-systemctl stop $(LEGACY) 2>/dev/null || true
	-systemctl disable $(LEGACY) 2>/dev/null || true
	rm -f $(DIR_SYSTEMD)/$(LEGACY).service
	rm -rf $(DIR_SYSTEMD)/$(LEGACY).service.d
	-systemctl stop $(INSTALL) 2>/dev/null || true
	-systemctl disable $(INSTALL) 2>/dev/null || true
	install -m 644 $(INSTALL).service $(DIR_SYSTEMD)/$(INSTALL).service
	systemctl daemon-reload
	systemctl enable $(INSTALL)
	systemctl start $(INSTALL) || echo "Warning: Failed to start $(INSTALL)"
install: install_target install_config install_udev install_service
restart:
	systemctl restart $(INSTALL)
.PHONY: install install_target install_config install_udev install_service
.PHONY: restart

##
