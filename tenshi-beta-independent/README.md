# Independent Tenshi-style Finder

This is an isolated implementation track. It does not modify the existing UNKNOWN key loader or the original developer's service.

## Files
- `Tenshi-Beta-Independent.lua`: client/UI and game-side egg scanner.
- `server.cjs`: independent HTTP API.
- `config.json`: public client configuration template; set the deployed API origin and room credential after deployment.
- `host-config.example.json`: private server configuration template.

## Compatibility status
The available readable source used to reconstruct the UI is archived public v0.4.3 / UI18, not the packed Beta 0.6 source. This is therefore not yet a verified 1:1 Beta 0.6 rebuild. Beta 0.6-only changes still need to be compared and ported.

## Premium behavior
Premium is enabled locally in this independent client. There is **no Premium access key, no Premium code entry, and no Premium-key validation** in this implementation. Premium feed requests receive the independent service's top-10 tier.

The server still uses a separate `roomKey` for basic API request authorization and abuse control. This is not a Premium unlock key and is not shown as a user-entered Premium code. Because a client-side credential can be extracted, enforce host-side rate limits and rotate it if abused.

## API routes
- `GET /health`
- `POST /v1/report`
- `GET /v1/eggs`
- `POST /v1/join`

## Run the Node backend
1. Copy `host-config.example.json` to `host-config.json`.
2. Set `roomKey` to a random string of at least 32 characters.
3. Run `npm start` with Node.js 20 or newer.
4. Set the public API origin and matching `roomKey` in the client `config.json`.

Do not commit `host-config.json` or real credentials.

## Testing
The code has not yet been run inside Roblox or deployed to a live host. Verify `/health`, reporting, Premium feed, reservations, and teleport behavior before treating it as production-ready.
