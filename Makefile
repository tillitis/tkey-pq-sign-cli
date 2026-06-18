# Check for OS
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	shasum = shasum -a 512
	BUILD_CGO_ENABLED ?= 1
else
	shasum = sha512sum
	BUILD_CGO_ENABLED ?= 0
endif

IMAGE=ghcr.io/tillitis/tkey-builder:4

.PHONY: all
all: check-signer-hash tkey-pq-sign-cli

.PHONY: windows
windows: tkey-pq-sign-cli.exe

DESTDIR=/
PREFIX=/usr/local
SYSTEMDDIR=/etc/systemd
UDEVDIR=/etc/udev
destbin=$(DESTDIR)/$(PREFIX)/bin
destman1=$(DESTDIR)/$(PREFIX)/share/man/man1
destunit=$(DESTDIR)/$(SYSTEMDDIR)/user
destrules=$(DESTDIR)/$(UDEVDIR)/rules.d
.PHONY: install
install:
	install -Dm755 tkey-pq-sign-cli $(destbin)/tkey-pq-sign-cli
	strip $(destbin)/tkey-pq-sign-cli
	install -Dm644 system/60-tkey.rules $(destrules)/60-tkey.rules
	install -Dm644 doc/tkey-pq-sign-cli.1 $(destman1)/tkey-pq-sign-cli.1
	gzip -n9f $(destman1)/tkey-pq-sign-cli.1

.PHONY: uninstall
uninstall:
	rm -f \
	$(destbin)/tkey-pq-sign-cli \
	$(destrules)/60-tkey.rules \
	$(destman1)/tkey-pq-sign-cli.1.gz

.PHONY: reload-rules
reload-rules:
	udevadm control --reload
	udevadm trigger

podman:
	podman run --arch=amd64 --rm --mount type=bind,source=$(CURDIR),target=/src --mount type=bind,source=$(CURDIR)/../tkey-pq-device-sign,target=/tkeysign -w /src -it $(IMAGE) make -j

TKEY_SIGN_VERSION ?= $(shell git describe --dirty --always | sed -n "s/^v\(.*\)/\1/p")
# .PHONY to let go-build handle deps and rebuilds
.PHONY: tkey-pq-sign-cli
tkey-pq-sign-cli:
	CGO_ENABLED=$(BUILD_CGO_ENABLED) go build -ldflags "-w -X main.version=$(TKEY_SIGN_VERSION) -X main.signerAppNoTouch=$(TKEY_SIGNER_APP_NO_TOUCH)  -buildid=" -trimpath -buildvcs=false -o tkey-pq-sign-cli ./cmd/tkey-pq-sign-cli

.PHONY: tkey-pq-sign-cli.exe
tkey-pq-sign-cli.exe:
	GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -ldflags "-w -X main.version=$(TKEY_SIGN_VERSION) -X main.signerAppNoTouch=$(TKEY_SIGNER_APP_NO_TOUCH)  -buildid=" -trimpath -o tkey-pq-sign-cli.exe ./cmd/tkey-pq-sign-cli

doc/tkey-pq-sign-cli.1: doc/tkey-pq-sign-cli.scd
	scdoc < $^ > $@

.PHONY: check-signer-hash
check-signer-hash:
	$(shasum) -c pqsigner.bin.sha512

.PHONY: clean
clean:
	rm -f tkey-pq-sign-cli tkey-pq-sign-cli.exe

.PHONY: lint
lint:
	GOOS=linux   golangci-lint run
	GOOS=windows golangci-lint run
