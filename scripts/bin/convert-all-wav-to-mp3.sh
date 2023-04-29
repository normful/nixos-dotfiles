#!/usr/bin/env bash

set -o xtrace
set -o errexit
shopt -s globstar nullglob dotglob

# Summary of libmp3lame quality settings copied from https://trac.ffmpeg.org/wiki/Encode/MP3
#
# 	avg	range
# 	kbit/s	kbit/s	
# 0	245	220-260	
# 1	225	190-250
# 2	190	170-210	<- this script's default
# 3	175	150-195	
# 4	165	140-185	
# 5	130	120-150	
# 6	115	100-130
# 7	100	80-120
# 8	85	70-105
# 9	65	45-85
quality="${1:2}"

for filename in **/*.wav; do
	ffmpeg -i "$filename" \
		-acodec libmp3lame \
		-aq "$quality" \
		-y \
		"${filename/%wav/mp3}" 
done
