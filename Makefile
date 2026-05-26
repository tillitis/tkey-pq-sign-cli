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
all: check-signer-hash tkey-sign-pq

.PHONY: windows
windows: tkey-sign-pq.exe

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
	install -Dm755 tkey-sign-pq $(destbin)/tkey-sign-pq
	strip $(destbin)/tkey-sign-pq
	install -Dm644 system/60-tkey.rules $(destrules)/60-tkey.rules
	install -Dm644 doc/tkey-sign-pq.1 $(destman1)/tkey-sign-pq.1
	gzip -n9f $(destman1)/tkey-sign-pq.1

.PHONY: uninstall
uninstall:
	rm -f \
	$(destbin)/tkey-sign-pq \
	$(destrules)/60-tkey.rules \
	$(destman1)/tkey-sign-pq.1.gz

.PHONY: reload-rules
reload-rules:
	udevadm control --reload
	udevadm trigger

podman:
	podman run --arch=amd64 --rm --mount type=bind,source=$(CURDIR),target=/src --mount type=bind,source=$(CURDIR)/../tkeysign-pq,target=/tkeysign -w /src -it $(IMAGE) make -j

TKEY_SIGN_VERSION ?= $(shell git describe --dirty --always | sed -n "s/^v\(.*\)/\1/p")
# .PHONY to let go-build handle deps and rebuilds
.PHONY: tkey-sign-pq
tkey-sign-pq:
	CGO_ENABLED=$(BUILD_CGO_ENABLED) go build -ldflags "-w -X main.version=$(TKEY_SIGN_VERSION) -X main.signerAppNoTouch=$(TKEY_SIGNER_APP_NO_TOUCH)  -buildid=" -trimpath -buildvcs=false -o tkey-sign-pq ./cmd/tkey-sign

.PHONY: tkey-sign-pq.exe
tkey-sign-pq.exe:
	GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -ldflags "-w -X main.version=$(TKEY_SIGN_VERSION) -X main.signerAppNoTouch=$(TKEY_SIGNER_APP_NO_TOUCH)  -buildid=" -trimpath -o tkey-sign-pq.exe ./cmd/tkey-sign

doc/tkey-sign-pq.1: doc/tkey-sign-pq.scd
	scdoc < $^ > $@

.PHONY: check-signer-hash
check-signer-hash:
	$(shasum) -c pqsigner.bin.sha512

.PHONY: clean
clean:
	rm -f tkey-sign-pq tkey-sign-pq.exe

.PHONY: lint
lint:
	GOOS=linux   golangci-lint run
	GOOS=windows golangci-lint run
