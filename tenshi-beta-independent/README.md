# Independent Tenshi-style Finder

This folder is a clean-room implementation track, isolated from the existing UNKNOWN key loader.

## Current status
- Independent Git branch: `tenshi-beta-independent`
- Backend starter: Node.js HTTP service
- Own room credential and Premium credential; no dependency on the original host
- API compatibility target: report sightings, fetch ranked eggs, reserve joins

## Important compatibility note
The archived public v0.4.3 source is not the same build as Beta 0.6. The current Beta 0.6 client is packed, and its live host implementation/configuration is not present in the public repository. This project therefore starts with the observable API contract and must be tested against a reconstructed client before it can be called a full clone.

## Run
1. Copy `host-config.example.json` to `host-config.json`.
2. Set long random values for `roomKey` and `premiumKey`.
3. Run `npm start`.

Never commit `host-config.json`; it contains private credentials.
