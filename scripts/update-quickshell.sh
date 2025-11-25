#!/usr/bin/env bash
set -e

git fetch quickshell_upstream calendar

git branch -D quickshell_upstream_calendar
git checkout -b quickshell_upstream_calendar quickshell_upstream/calendar


git subtree split -P dots/.config/quickshell -b quickshell_subfolder


git checkout main

git subtree merge --prefix=.config/quickshell quickshell_subfolder --squash

hyprctl reload
