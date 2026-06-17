# Release notes

## v0.0.1

Migrated from
[https://github.com/tillitis/tkey-sign-cli](https://github.com/tillitis/tkey-sign-cli)
and renamed to tkey-pq-sign-cli.

- Upgraded signing algorithm to
[ML-DSA-44](https://csrc.nist.gov/pubs/fips/204/final) (post-quantum
signature scheme, FIPS 204) (uses MLDSA-pure)
- Uses
[github.com/cloudflare/circl](https://github.com/cloudflare/circl) for
ML-DSA-44 until Go 1.27 ships it in the standard library
- Depends on updated
[tkey-pq-sign](https://github.com/tillitis/tkey-pq-sign) library
adapted for ML-DSA-44
- Embeds [tkey-pq-device-signer
v0.0.1](https://github.com/tillitis/tkey-pq-device-signer)
- Implements external MU computation for messages
