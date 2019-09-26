#!/bin/bash

VERSION=`awk '{ print $3; }' < version.inc | tr -d '\\"'`

dasm fastrs.asm -ofastrs.bin -DPAL
xa -M -o devaid-v$VERSION-pal devaid.asm

dasm fastrs.asm -ofastrs.bin -DNTSC
xa -M -o devaid-v$VERSION-ntsc devaid.asm

rm fastrs.bin

zip devaid-v$VERSION.zip devaid-*
