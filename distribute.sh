#!/bin/sh

# Generate a clean distribution package, without documentation, LDoc config
# files and other uneeded stuff. The output ZIP archive will be placed in
# dist/tech_api.zip

mkdir -p dist
rm -rf dist/tech_api.zip

zip -r dist/tech_api.zip . -x *.git* -x ".gitignore" -x "*.sh" -x "*.ld" -x docs/\* -x ldoc/\* -x "*.md" -x dist/\*
