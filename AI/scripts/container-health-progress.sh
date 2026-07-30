#!/bin/sh

health_url=$1
progress_root=$2

if curl --fail --silent "$health_url" >/dev/null; then
  exit 0
fi

largest_open_file_size=0
for descriptor in /proc/1/fd/*; do
  target=$(readlink "$descriptor" 2>/dev/null)
  case "$target" in
    "$progress_root"/*)
      file_size=$(stat -Lc %s "$descriptor" 2>/dev/null)
      if [ -n "$file_size" ] && [ "$file_size" -gt "$largest_open_file_size" ]; then
        largest_open_file_size=$file_size
      fi
      ;;
  esac
done

if [ "$largest_open_file_size" -gt 0 ]; then
  received_size=$(awk -v bytes="$largest_open_file_size" 'BEGIN { printf "%.2f GB", bytes / 1000000000 }')
  printf 'Receiving service data · %s received\n' "$received_size"
else
  printf 'Initializing service\n'
fi

exit 1
