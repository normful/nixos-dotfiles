#!/usr/bin/env bash

set -o xtrace
set -o errexit
shopt -s globstar nullglob dotglob

# Docs the audio quality option `-aq` (aka `-qscale:a`) when using the libvorbis codec.
# (`-aq` values depend on the codec used.)
#
# Quote from http://trac.ffmpeg.org/wiki/TheoraVorbisEncodingGuide
# > Range is -1.0 to 10.0, where 10.0 is highest quality. Default is -q:a 3 with a
# > target of 112kbps. The formula 16×(q+4) is used below 4, 32×q is used
# > below 8, and 64×(q-4) otherwise. Examples: 112=16×(3+4), 160=32×5, 200=32×6.25,
# > 384=64×(10-4).
quality="${1:0}"

for filename in **/*.mp3; do
	ffmpeg -i "$filename" \
		-acodec libvorbis \
		-aq "$quality" \
		-y \
		"${filename/%mp3/ogg}" 
done
