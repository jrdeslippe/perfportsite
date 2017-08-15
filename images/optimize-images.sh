#!/bin/bash
width=200
for f in cori theta titan; do
    src=$f.jpg
    out=$f.opt.jpg
    convert $src -resize $width -sampling-factor 4:2:0 -strip -quality 85 -interlace JPEG -colorspace RGB $out
done
