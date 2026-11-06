# Independent Tenshi-style Finder

This is an isolated implementation track. It does not modify the existing UNKNOWN key loader or the original developer's service.

## Files
- `Tenshi-Beta-Independent.lua`: small loader that downloads and concatenates the client source chunks.
- `client-source/source-01.lua` through `source-10.lua`: recovered and adapted client/UI and game-side egg scanner.
- `server.cjs`: optional standalone Node.js API implementation.
- `config.json`: public API endpoint configuration.
- `host-config.example.json`: optional local Node.js port configuration.

## Live API
The independent Cloudflare Worker is deployed at:
`https://tenshi-beta-independent.tenshifinder.workers.dev`

## Premium
Premium is enabled automatically in this independent client. There is no Premium key, no Premium code entry, and no Premium-key validation. The feed requests the independent service's global top 10.

No user-entered room key is required. The API is public; request validation and short-lived snapshots limit malformed data and stale entries. The service is a community report feed, so its accuracy depends on active clients reporting sightings.

## API routes
- `GET /health`
- `POST /v1/report`
- `GET /v1/eggs`
- `POST /v1/join`

## Source provenance and compatibility
The packed client blob was recovered from upstream release commit `2b1e0978d807d3d4f3b5f9330b22fd1760e9bd63`. Its decoded embedded source header identifies **Public v0.4.3 / UI18**. The release commit is titled Beta 0.6, but the embedded source does not establish that every Beta 0.6 change is present. This is therefore not claimed to be a verified 1:1 Beta 0.6 rebuild.

The independent client was rebuilt from that clean decoded source. Its Premium flag is enabled locally and the old room/viewer-key headers and original config fetches were removed. Random-server listing and its diagnostics poll are hidden/disabled because the independent Worker does not currently implement those original endpoints.

## Testing
The Worker deployment and `/health` response were confirmed. The client source chunks and loader were checked in GitHub, including one `run()` definition and no remaining `roomKey` or `X-NYX` references. The full in-game report/feed/reservation/teleport flow has **not** been runtime-tested inside Roblox.
