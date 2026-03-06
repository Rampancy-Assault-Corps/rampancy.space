#!/bin/bash

set -e

cd "$(dirname "${BASH_SOURCE[0]}")/.."

gcloud services enable \
    firebasehosting.googleapis.com \
    run.googleapis.com \
    cloudfunctions.googleapis.com \
    --project rampancy-space

cd rampancy_assault_corps_web
jaspr build
cd ..
firebase deploy --only hosting:release --project rampancy-space
