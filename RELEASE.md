# Release notes

## v1.0.0

Migrated from https://github.com/tillitis/tkey-sign-cli and renamed to tkey-sign-cli-pq

- Upgraded signing algorithm to [ML-DSA-44](https://csrc.nist.gov/pubs/fips/204/final)
  (post-quantum signature scheme, FIPS 204) (uses MLDSA-pure)
- Uses [github.com/cloudflare/circl](https://github.com/cloudflare/circl) for
  ML-DSA-44 until Go 1.27 ships it in the standard library
- Depends on updated [tkeysign-pq](https://github.com/tillitis/tkeysign-pq) library
  adapted for ML-DSA-44
- Embeds [tkey-device-pqsigner v1.0.0](https://github.com/tillitis/tkey-device-pqsigner)