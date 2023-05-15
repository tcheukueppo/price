#!/bin/sh

for cmd in perltidy git ; do
   command -v $cmd >/dev/null || {
      printf '%s: ERROR: %s not installed\n' "$0" "$cmd" >&2
      exit 1
   }
done

git status | grep '^[[:cntrl:]]*modified:' | grep -E 'bin/|\.(pm|t)$' | perl -nE 'say +(split)[-1]' | while read file ; do
   printf "perltidying '%s'\n" "$file"
   perltidy -b -bext='/' -pro=.perltidyrc "$file"
done
