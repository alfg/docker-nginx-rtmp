#!/usr/bin/env bash
set -e

if [ ! -v "${MAX_MUXING_QUEUE_SIZE}" ]; then
  MAX_MUXING_QUEUE_SIZE_ARG="-max_muxing_queue_size ${MAX_MUXING_QUEUE_SIZE} "
fi

if [ ! -v "${ANALYZEDURATION}" ]; then
  ANALYZEDURATION_ARG="-analyzeduration ${ANALYZEDURATION} "
fi

quality1=('480' '256k' '64k' 'low' '448000')
quality2=('720' '768k' '128k' 'mid' '448000')
quality3=('960' '1240k' '128k' 'high' '1152000')
quality4=('1280' '1920k' '128k' 'hd720' '2048000')

if [ -v ${SINGLE_STREAM} ]; then
  qualities=(quality1 quality2 quality3 quality4)
else
  qualities=(quality4)
fi

output_execpush="/usr/local/bin/ffmpeg $ANALYZEDURATION_ARG-async 1 -vsync -1 -hwaccel cuda -hwaccel_output_format cuda -c:v h264_cuvid -i rtmp://localhost:1935/stream/\$name "
output_hlsvariants=""
for quality in "${qualities[@]}"; do
  declare -n qualitylist=$quality
  output_execpush="$output_execpush"$'\n\t\t'"-c:v h264_nvenc -c:a aac -b:v ${qualitylist[1]} -b:a ${qualitylist[2]} -vf \"scale_npp=${qualitylist[0]}:trunc(ow/a/2)*2\" -zerolatency 1 $MAX_MUXING_QUEUE_SIZE_ARG-f flv rtmp://localhost:1935/hls/\$name_${qualitylist[3]}"
  output_hlsvariants=$'\n\t\t'"hls_variant _${qualitylist[3]} BANDWIDTH=${qualitylist[4]};"$'\n'"${output_hlsvariants}"
done

export EXECPUSH="$output_execpush"
export HLSVARIANTS="$output_hlsvariants"

envsubst "$(env | sed -e 's/=.*//' -e 's/^/\$/g')" < \
  /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

nginx
