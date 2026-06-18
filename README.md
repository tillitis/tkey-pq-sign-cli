

# tkey-pq-sign-cli

`tkey-pq-sign-cli` creates and verifies cryptographic signatures of files.
The signature is created by the [signer device
app](https://github.com/tillitis/tkey-device-pqsigner) running on the
[Tillitis](https://tillitis.se/) TKey. The signer is automatically
loaded into the TKey by `tkey-pq-sign-cli` when signing or extracting the
public key. The measured private key never leaves the TKey.

`tkey-pq-sign-cli` uses ML-DSA-Pure and ML-DSA-44 algorithm for signing where
the T-Key signer device app uses external Mu when signing the messages.
The client will compute the Mu value of the message and send to the device-app.
So no limitation on how big a file can be while still using ML-DSA-Pure.

See [ML-DSA draft](https://www.ietf.org/archive/id/draft-connolly-cfrg-ml-dsa-security-considerations-01.html#name-external-mu) about external Mu.

At the moment the Go module cloudflare/circl is implemented for ML-DSA.
There is a plan to replace this with Go standard module for ML-DSA when it is released.
Planned release of the Go standard module is with release of Go version 1.27 in august 2026.

See [Release notes](RELEASE.md).

## Usage

Get a public key, possibly modifying the key pair by using a User
Supplied Secret, and storing the public key in file `-p pubkey`.

```
tkey-pq-sign-cli -G/--getkey [-d/--port device] [-s/--speed speed]
[--uss] [--uss-file secret-file] -p/--public pubkey
```

Sign a file, specified with `-m message`, possibly modifying the
measured key pair by using a User Supplied Secret, and storing the
signature in `-x sigfile` or, by default, in `message.sig`. You need
to supply the public key file as well which `tkey-pq-sign-cli` will
automatically verify that it's the expected public key.

```
tkey-pq-sign-cli -S/--sign [-d/--port device] [-s speed] -m message
[--uss] [--uss-file secret-file] -p/--public pubkey [-x sig-file]
```

Verify a signature of file `-m message` with public key in `-p pubkey`.
Signature is by default in `message.sig` but can be specified
with `-x sigfile`. Doesn't need a connected TKey.

```
tkey-pq-sign-cli -V/--verify -m message -p/--public pubkey [-x sigfile]
```


See the manual page for details.

## Examples

All examples either load the device app automatically or works with an
already loaded device app.

Store the public key in a file.
```
$ tkey-pq-sign-cli -G -p key.pub
```

Sign a file using the signer's basic secret or the identity of an
already loaded signer while also checking that you have the right
public key in a file:

```
$ tkey-pq-sign-cli -S -m message.txt -p key.pub
```

Verify a signature over a message file with the signature in the
default "message.txt.sig" file:

```
$ tkey-pq-sign-cli -V -p key.pub -m message.txt
```


## Build & install

The easiest way is to:

```
$ go install github.com/tillitis/tkey-pq-sign-cli/cmd/tkey-pq-sign-cli@latest
```

After this the `tkey-pq-sign-cli` command should be available in your
`$GOBIN` directory.

Note that this doesn't set the version and other stuff you get if you
use `make`.

### Building

If you have Go and make installed, a simple:

```
$ make
```

or, for a Windows executable,

```
$ make tkey-pq-sign-cli.exe
```

should build `tkey-pq-sign-cli`. A pre-compiled signer device app binary is
included in the repo and will be automatically embedded.

Cross compiling the usual Go way with `GOOS` and `GOARCH` environment
variables works for most targets but currently doesn't work for
`GOOS=darwin` since the `go.bug.st/serial` package relies on macOS
shared libraries for port enumeration.

### Building with tkey-builder

If you want to use the tkey-builder image and you have `make` you can
run:

```
$ podman pull ghcr.io/tillitis/tkey-builder:4
$ make podman
```

or run tkey-builder directly with Podman:

```
$ podman run --rm --mount type=bind,source=$(CURDIR),target=/src -w /src -it ghcr.io/tillitis/tkey-builder:4 make -j
```

Note that building with Podman by default creates a Linux binary. Set
`GOOS` and `GOARCH` with `-e` in the call to `podman run` to desired
target. Again, this won't work with a macOS target.

### Installing on Linux

You can install `tkey-pq-sign-cli` and reload the Linux udev rules to get
access to the TKey with:

```
$ sudo make install
$ sudo make reload-rules
```

### Reproducible builds

You should be able to build a binary that is a exact copy of our
release binaries if you use the same Go compiler, at least for the
statically linked Linux and Windows binaries.

Please see [the official
releases](https://github.com/tillitis/tkey-pq-sign-cli/releases) for
digests and details about the build environment.

### Building with another signer

For convenience, and to be able to support `go install` the signer
device app binary is included in `cmd/tkey-pq-sign-cli`.

If you want to replace the signer used you have to:

1. Compile your own signer and place it in `cmd/tkey-pq-sign-cli`.
2. Change the path to the embedded signer in `cmd/tkey-pq-sign-cli/main.go`.
   Look for `go:embed...`.
3. Change the `appName` directly under the `go:embed` to whatever your
   signer is called, so the agent reports this correctly with
   `--version`.
4. Compute a new SHA-512 hash digest for your binary, typically by
   something like `sha512sum cmd/tkey-pq-sign-cli/pqsigner.bin-v0.0.7` and put
   the resulting output in the file `signer.bin.sha512` at the top
   level.
5. `make` in the top level.

## Building the signer

1. See [the Developer Handbook](https://dev.tillitis.se/) for setup of
   development tools. We recommend you use tkey-builder.
2. See the instructions in the [tkey-pq-device-signer
   repo](https://github.com/tillitis/tkey-pq-device-signer).
3. Copy its `signer/app.bin` to
   `cmd/tkey-pq-sign-cli/signer.bin-${signer_version}` and run `make`.

To help prevent unpleasant surprises we keep a digest of the signer in
`cmd/tkey-ssh-agent/signer.bin.sha512`. The compilation will fail if
this is not the expected binary. If you really intended to build with
another signer, see [Building with another
signer](#building-with-another-signer) above.

## Licenses and SPDX tags

Unless otherwise noted, the project sources are copyright Tillitis AB,
licensed under the terms and conditions of the "BSD-2-Clause" license.
See [LICENSE](LICENSE) for the full license text.

Until Nov 14, 2025, the license was GPL-2.0 Only.

External source code we have imported are isolated in their own
directories. They may be released under other licenses. This is noted
with a similar `LICENSE` file in every directory containing imported
sources.

The project uses single-line references to Unique License Identifiers
as defined by the Linux Foundation's [SPDX project](https://spdx.org/)
on its own source files, but not necessarily imported files. The line
in each individual source file identifies the license applicable to
that file.

The current set of valid, predefined SPDX identifiers can be found on
the SPDX License List at:

https://spdx.org/licenses/

We attempt to follow the [REUSE
specification](https://reuse.software/).
