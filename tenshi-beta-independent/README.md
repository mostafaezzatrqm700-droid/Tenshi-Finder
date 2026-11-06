# Independent Tenshi-style Finder

This folder is an isolated implementation track. It does not modify the existing UNKNOWN key loader.

## Files
- `Tenshi-Beta-Independent.lua`: client/UI and game-side egg scanner.
- `server.cjs`: independent HTTP API.
- `config.json`: public client configuration template; replace its placeholders after deploying the API.
- `host-config.example.json`: private server configuration template.

## Current compatibility status
The available readable source used to reconstruct the UI is archived public v0.4.3 / UI18, not the packed Beta 0.6 source. The client therefore preserves the visible finder workflow and API shape that can be verified from that source, but it is **not yet a verified 1:1 Beta 0.6 rebuild**. Beta 0.6-only changes still need to be compared and ported.

## API routes
- `GET /health`
- `POST /v1/report`
- `GET /v1/eggs`
- `POST /v1/join`

## Run the Node backend
1. Copy `host-config.example.json` to `host-config.json`.
2. Set `roomKey` to a random string of at least 32 characters.
3. Set a different `premiumKey` of at least 24 characters.
4. Run `npm start` with Node.js 20 or newer.
5. Set the public API origin and the same `roomKey` in `config.json`.

Do not commit `host-config.json`. The client needs the room credential to submit sightings; treat it as a shared client credential, not as a durable secret. Apply rate limits at the host and rotate it if it is abused.

## Premium
The client exposes its Premium access UI. Enter the `premiumKey` configured on the independent backend. The server enforces Premium access and the global top-10 tier; changing a local UI flag does not grant server-side access.

## Testing
The code has been committed but has not yet been run inside Roblox or deployed to a live host. Verify /health, reporting, public feed, Premium feed, reservations, and teleport behavior before treating it as production-ready.
