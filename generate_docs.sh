#!/bin/bash

# This script generates documentation using SwiftDoc in a format suitable for GitHub Pages

swift-doc generate Sources --module-name Disruptive -o docs --format html --base-url https://vegather.github.io/Disruptive
