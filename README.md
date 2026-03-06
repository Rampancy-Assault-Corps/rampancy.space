# rampancy.space

Local development runs with a gateway on `:8080`:
- frontend on `:8082`
- backend on `:8081`
- gateway routes `/auth/**`, `/api/**`, and `/keepAlive` to backend
- all other paths go to frontend

## Local Run

1. Create local env file:
   - `cp config/local.env.example config/local.env`
2. Fill required values in `config/local.env`:
   - `GOOGLE_CLOUD_PROJECT`
   - `GOOGLE_APPLICATION_CREDENTIALS`
   - `ENABLE_ACCOUNT_LINKING=true`
   - Discord/Bungie OAuth values
   - base64 keys (`SESSION_SIGNING_KEY_BASE64`, `OAUTH_STATE_SIGNING_KEY_BASE64`, `TOKEN_ENCRYPTION_KEY_BASE64`) that decode to 32 bytes
3. Start local stack:
   - `./scripts/local_dev.sh`
4. Open:
   - `http://127.0.0.1:8080`

If `config/local.env` is not found, `scripts/local_dev.sh` runs with your current shell environment.

## Deploy

1. Create deploy env:
   - `cp config/deploy.env.example config/deploy.env`
2. Fill `config/deploy.env` with your production OAuth values if you want Bungie/Discord linking enabled.

```bash
# Firebase rules
./scripts/deploy_firebase_config.sh

# Server
./scripts/deploy_server.sh

# Site
cd rampancy_assault_corps_web && jaspr build && cd .. && firebase deploy --only hosting:release --project rampancy-space

# Full deploy
./scripts/deploy_all.sh
```
