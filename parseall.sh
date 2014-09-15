#!/bin/sh

for f in bib/* ; do
    ./parse.rb $f > /dev/null
done
