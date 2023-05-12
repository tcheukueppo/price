#!/bin/sh

for i in $(git status | grep -E '\.(bak|ERR)$' | perl -nE 'say +(split)[-1]') ; do rm -v "$i"; done
