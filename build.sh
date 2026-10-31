#!/bin/bash
cd "$(dirname "$0")"
mkdir -p FolderScope.app/Contents/MacOS
swift build && cp .build/debug/FolderScope FolderScope.app/Contents/MacOS/ && open FolderScope.app
