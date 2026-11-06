# Independent Tenshi-style Finder

This is an isolated implementation track. It does not modify the existing UNKNOWN key loader or the original developer's service.

## Files
- `Tenshi-Beta-Independent.lua`: client/UI and game-side egg scanner.
- `server.cjs`: optional standalone Node.js API implementation.
- `config.json`: public API endpoint configuration.
- `host-config.example.json`: optional local Node.js port configuration.

## Live API
The independent Cloudflare Worker is deployed at:
`https://tenshi-beta-independent.tenshifinder.workers.dev`

## Premium
Premium is enabled automatically in this independent client. There is no Premium key, no Premium code entry, and no Premium-key validation. The feed returns the independent service's global top 10.

No user-entered room key is required either. The API is public; request validation and short-lived snapshots limit malformed data and stale entries. The service is a community report feed, so its accuracy depends on active clients reporting sightings.

## API routes
- `GET /health`
- `POST /v1/report`
- `GET /v1/eggs`
- `POST /v1/join`

## Compatibility status
The available readable source used to reconstruct the UI is archived public v0.4.3 / UI18, not the packed Beta 0.6 source. This is therefore not yet a verified 1:1 Beta 0.6 rebuild. Beta 0.6-only changes still need to be compared and ported.

## Testing
Cloudflare deployment completed. The live health endpoint and full in-game report/feed/reservation/teleport flow still require runtime verification inside Roblox.
