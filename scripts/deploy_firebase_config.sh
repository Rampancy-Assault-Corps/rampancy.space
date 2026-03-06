#!/bin/bash

set -e

cd "$(dirname "${BASH_SOURCE[0]}")/.."

firebase deploy --only firestore,storage --project rampancy-space
