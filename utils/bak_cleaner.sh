#!/bin/sh

for i in $(git status | grep \.bak$ | perl -nE 'say +(split)[-1]') ; do rm -v $i; done
