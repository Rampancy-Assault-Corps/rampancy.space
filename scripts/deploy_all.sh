#!/bin/bash

set -e

cd "$(dirname "${BASH_SOURCE[0]}")/.."

./scripts/deploy_firebase_config.sh
./scripts/deploy_server.sh
./scripts/deploy_site.sh
