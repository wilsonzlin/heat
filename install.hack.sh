#!/usr/bin/env bash

set -e

ORIG_DIR="$(dirname "$0")"
ORIG_DIR="$(realpath "$ORIG_DIR")"
cd "$ORIG_DIR"

SRC="$(realpath ./src/)"

DST="./dist/"

HHVM_INI_FILE="$DST/conf/hhvm.ini"
HHVM_FILE_SOCKET="$DST/logs/hhvm.sock"

#sed -i "s@<COMPILE_PARAM_HHVM_DOCROOT>@$DST/app/php/@" "$DST/conf/nginx-hhvm.conf"
#sed -i "s@<COMPILE_PARAM_HHVM_FILE_SOCKET>@$HHVM_FILE_SOCKET@" "$DST/conf/nginx-hhvm.conf"

echo "pid = $DST/logs/hhvm.pid" >> "$HHVM_INI_FILE"
#echo "hhvm.server.file_socket = $HHVM_FILE_SOCKET" >> "$HHVM_INI_FILE"
#echo "hhvm.server.type = fastcgi" >> "$HHVM_INI_FILE"
echo "hhvm.server.port = 1026" >> "$HHVM_INI_FILE"
echo "hhvm.server.type = proxygen" >> "$HHVM_INI_FILE"
echo "hhvm.server.thread_count = 10000" >> "$HHVM_INI_FILE"

echo "hhvm.server.exit_on_bind_fail = true" >> "$HHVM_INI_FILE"
echo "hhvm.server.expose_hphp = false" >> "$HHVM_INI_FILE"
echo "hhvm.php7.all = true" >> "$HHVM_INI_FILE"
echo "hhvm.log.use_log_file = true" >> "$HHVM_INI_FILE"
echo "hhvm.log.file = $DST/logs/hhvm-error.log" >> "$HHVM_INI_FILE"
#echo "hhvm.log.level = Verbose" >> "$HHVM_INI_FILE"
echo "hhvm.repo.authoritative = true" >> "$HHVM_INI_FILE"
echo "hhvm.repo.central.path = $DST/app/hhvm.hhbc" >> "$HHVM_INI_FILE"
echo "hhvm.server.source_root = $DST/app/hack/" >> "$HHVM_INI_FILE"

echo "mysqli.allow_persistent = true" >> "$HHVM_INI_FILE"
echo "mysqli.max_persistent = 0" >> "$HHVM_INI_FILE"

mkdir -p "$DST/app/hack/"
cp hack/* "$DST/app/hack/"

find "$DST/app/hack/" -name "*.hh" > hack-index.tmp
hhvm --hphp -t hhbc -v AllVolatile=false -l3 --input-list hack-index.tmp -o "$DST/app/"
rm hack-index.tmp