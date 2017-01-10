#!/usr/bin/env bash

set -e

CPU_CORE_COUNT=$(nproc --all)
echo "CPU cores: $CPU_CORE_COUNT"

if [ "$1" == "dep" ]
    then
        if [ -n "$(command -v dnf)" ]
            then sudo dnf install readline-devel pcre-devel openssl-devel gcc
        elif [ -n "$(command -v yum)" ]
            then sudo yum install readline-devel pcre-devel openssl-devel gcc
        elif [ -n "$(command -v apt)" ]
            then sudo apt install libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make build-essential
        elif [ -n "$(command -v apt-get)" ]
            then sudo apt-get install libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make build-essential
        fi
fi

ORIG_DIR="$(dirname "$0")"
ORIG_DIR="$(realpath "$ORIG_DIR")"
cd "$ORIG_DIR"

SRC="$(realpath ./src/)"

DST="./dist/"
rm -rf "$DST"
mkdir -p "$DST"
DST="$(realpath "$DST")"

cd "$SRC/nginx"

rm -rf openresty/

tar -zvxf openresty-1.11.2.2.tar.gz

mv openresty-1.11.2.2/ openresty/

cp __patches/* openresty/bundle/nginx-1.11.2/src/http/

cd openresty
# WARNING: FastCGI module is needed for HHVM
./configure -j$CPU_CORE_COUNT --prefix="$DST" \
    --with-pcre-jit \
    --with-ipv6 \
    --with-http_v2_module \
    --without-http_echo_module \
    --without-http_xss_module \
    --without-http_coolkit_module \
    --without-http_set_misc_module \
    --without-http_form_input_module \
    --without-http_encrypted_session_module \
    --without-http_array_var_module \
    --without-http_rds_json_module \
    --without-http_rds_csv_module \
    --without-http_ssi_module \
    --without-http_userid_module \
    --without-http_autoindex_module \
    --without-http_geo_module \
    --without-http_map_module \
    --without-http_split_clients_module \
    --without-http_uwsgi_module \
    --without-http_scgi_module \
    --without-http_empty_gif_module \
    --without-http_browser_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module
make -j$CPU_CORE_COUNT
make install
cd ..

rm -rf openresty/

rm -rf "$DST/conf/"
mkdir -p "$DST/conf/"
cp conf/* "$DST/conf/"
sed -i "s@<COMPILE_PARAM_HHVM_DOCROOT>@$DST/app/php/@" "$DST/conf/nginx-hhvm.conf"

cd "$SRC"

HHVM_INI_FILE="$DST/conf/hhvm.ini"

# php options

echo "pid = $DST/logs/hhvm.pid" >> "$HHVM_INI_FILE"

# hhvm specific

echo "hhvm.server.port = 9000" >> "$HHVM_INI_FILE"
echo "hhvm.server.type = fastcgi" >> "$HHVM_INI_FILE"

echo "hhvm.server.default_document = index.php" >> "$HHVM_INI_FILE"
echo "hhvm.server.exit_on_bind_fail = true" >> "$HHVM_INI_FILE"
echo "hhvm.server.expose_hphp = false" >> "$HHVM_INI_FILE"
echo "hhvm.php7.all = true" >> "$HHVM_INI_FILE"
echo "hhvm.log.use_log_file = true" >> "$HHVM_INI_FILE"
echo "hhvm.log.file = $DST/logs/hhvm-error.log" >> "$HHVM_INI_FILE"
#echo "hhvm.log.level = Verbose" >> "$HHVM_INI_FILE"
echo "hhvm.repo.authoritative = true" >> "$HHVM_INI_FILE"
echo "hhvm.repo.central.path = $DST/app/hhvm.hhbc" >> "$HHVM_INI_FILE"

mkdir -p "$DST/app/resty/"
mkdir -p "$DST/app/express/"
mkdir -p "$DST/app/php/"
cp resty/* "$DST/app/resty/"
cp express/* "$DST/app/express/"
cp php/* "$DST/app/php/"

find "$DST/app/php/" -name "*.php" > php-index.tmp
hhvm --hphp -t hhbc -v AllVolatile=false -l3 --input-list php-index.tmp -o "$DST/app/"
rm php-index.tmp

cd "$ORIG_DIR"

export PATH="$(realpath "$ORIG_DIR/dist/bin"):$PATH"
#export LD_LIBRARY_PATH="$(realpath dist/luajit/lib):$LD_LIBRARY_PATH"

#opm get bungle/lua-resty-nettle
opm get jkeys089/lua-resty-hmac

cd "$DST/app/express"
npm install
rm package.json

cd "$ORIG_DIR"

exit 0