#!/bin/bash

set -e

cd "$(dirname "${BASH_SOURCE[0]}")/.."

./rampancy_assault_corps_server/script_deploy.sh
