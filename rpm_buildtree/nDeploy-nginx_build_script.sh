#!/bin/bash
#Author: Anoop P Alias

##Vars
#expecting 6/7 as the first arg to this scripts
#no sanitation is done as this would be mostly used by a person who knows what he is doing
OSVERSION=$1
NGINX_VERSION="1.11.10"
NGINX_RPM_ITER="4.el${OSVERSION}"
NPS_VERSION="1.11.33.4"
MY_RUBY_VERSION="2.3.1"
PASSENGER_VERSION="5.1.1"
CACHE_PURGE_VERSION="2.3"
NAXSI_VERSION="http2"
PS_NGX_EXTRA_FLAGS="--with-cc=/opt/rh/devtoolset-2/root/usr/bin/gcc"
OPENSSL_VERSION="1.0.2j"
LIBRESSL_VERSION="2.5.1"
SRCACHE_NGINX_MODULE="0.31"
NGX_DEVEL_KIT="0.3.0"
REDIS2_NGINX_MODULE="0.13"
SET_MISC_NGINX_MODULE="0.31"
REDIS_NGINX_MODULE="0.3.8"
HEADERS_MORE_NGINX_MODULE="0.32"
ECHO_NGINX_MODULE="0.60"



rm -rf nginx-module-*
rm -rf nginx-pkg
rm -rf nginx-${NGINX_VERSION}*
mkdir -p nginx-pkg/etc/nginx/{modules,modules.d,conf.auto}
mkdir -p nginx-pkg/usr/nginx/scripts
mkdir -p nginx-pkg/var/cache/nginx/ngx_pagespeed
mkdir -p nginx-pkg/var/log/nginx
mkdir -p nginx-pkg/var/run

for module in brotli geoip naxsi pagespeed passenger redis redis2 set_misc srcache_filter echo
do
  mkdir -p nginx-module-${module}-pkg/etc/nginx/{modules,modules.d,conf.auto,conf.d}
  mkdir -p nginx-module-${module}-pkg/usr/nginx/scripts
done
mkdir -p nginx-module-naxsi-pkg/etc/nginx/naxsi.d

yum --enablerepo=ndeploy -y install rpm-build libcurl-devel pcre-devel git xz-devel GeoIP-devel libbrotli-nDeploy
if [ ${OSVERSION} -eq 6 ];then
  rpm --import https://linux.web.cern.ch/linux/scientific6/docs/repository/cern/slc6X/i386/RPM-GPG-KEY-cern
  wget -O /etc/yum.repos.d/slc6-devtoolset.repo https://linux.web.cern.ch/linux/scientific6/docs/repository/cern/devtoolset/slc6-devtoolset.repo
  yum install devtoolset-2-gcc-c++ devtoolset-2-binutils
  rsync -a --exclude 'usr/lib' --exclude 'etc/nginx/naxsi.d/*' --exclude 'usr/nginx/scripts/*' --exclude 'etc/nginx/conf.d/naxsi_*' --exclude 'etc/nginx/conf.d/brotli.conf' --exclude 'etc/nginx/conf.d/pagespeed.conf' --exclude 'etc/nginx/conf.d/pagespeed_passthrough.conf' --exclude 'etc/nginx/fastcgi_params_geoip' --exclude 'etc/nginx/conf.auto/*' --exclude 'etc/nginx/modules/*' --exclude 'etc/nginx/modules.d/*' nginx-pkg-64-common/ nginx-pkg/
else
  rsync -a --exclude 'etc/rc.d' --exclude 'etc/nginx/naxsi.d/*' --exclude 'usr/nginx/scripts/*' --exclude 'etc/nginx/conf.d/naxsi_*' --exclude 'etc/nginx/conf.d/brotli.conf' --exclude 'etc/nginx/conf.d/pagespeed.conf' --exclude 'etc/nginx/conf.d/pagespeed_passthrough.conf' --exclude 'etc/nginx/fastcgi_params_geoip' --exclude 'etc/nginx/conf.auto/*' --exclude 'etc/nginx/modules/*' --exclude 'etc/nginx/modules.d/*' nginx-pkg-64-common/ nginx-pkg/
fi


gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | sudo bash -s stable --ruby=${MY_RUBY_VERSION}
. /usr/local/rvm/scripts/rvm
rvm use ruby-${MY_RUBY_VERSION}
echo ${MY_RUBY_VERSION}
/usr/local/rvm/rubies/ruby-${MY_RUBY_VERSION}/bin/gem install passenger -v ${PASSENGER_VERSION}
/usr/local/rvm/rubies/ruby-${MY_RUBY_VERSION}/bin/gem install fpm

wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
tar -xvzf nginx-${NGINX_VERSION}.tar.gz
cd nginx-${NGINX_VERSION}/


wget https://github.com/nbs-system/naxsi/archive/${NAXSI_VERSION}.tar.gz
tar -xvzf ${NAXSI_VERSION}.tar.gz
sed -i 's/hash_init.bucket_size = 512/hash_init.bucket_size = 2048/' naxsi-${NAXSI_VERSION}/naxsi_src/naxsi_utils.c
sed -i 's/hash_init.max_size  = 1024/hash_init.max_size  = 256000/' naxsi-${NAXSI_VERSION}/naxsi_src/naxsi_utils.c

# ngx_cache_purge project is mostly unmaintained ;ignoring
#wget http://labs.frickle.com/files/ngx_cache_purge-${CACHE_PURGE_VERSION}.tar.gz
#tar -xvzf ngx_cache_purge-${CACHE_PURGE_VERSION}.tar.gz

wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-beta.zip
unzip release-${NPS_VERSION}-beta.zip
cd ngx_pagespeed-release-${NPS_VERSION}-beta/
wget https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz
tar -xzvf ${NPS_VERSION}.tar.gz
cd ..

wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz
tar -zxf openssl-${OPENSSL_VERSION}.tar.gz

# LibreSSL
wget https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VERSION}.tar.gz
tar -zxf libressl-${LIBRESSL_VERSION}.tar.gz
cd libressl-${LIBRESSL_VERSION}
LIBRESSL_INSTALL_PATH=$(pwd)/.openssl
./configure LDFLAGS=-lrt --prefix=${LIBRESSL_INSTALL_PATH} && make install-strip
cd ..

git clone https://github.com/google/ngx_brotli.git
cd ngx_brotli && git submodule update --init && cd ..

# Modules from OpenResty project
wget -O srcache-nginx-module.tgz https://github.com/openresty/srcache-nginx-module/archive/v${SRCACHE_NGINX_MODULE}.tar.gz
wget -O ngx_devel_kit.tgz https://github.com/simpl/ngx_devel_kit/archive/v${NGX_DEVEL_KIT}.tar.gz
wget -O set-misc-nginx-module.tgz https://github.com/openresty/set-misc-nginx-module/archive/v${SET_MISC_NGINX_MODULE}.tar.gz
wget -O headers-more-nginx-module.tgz https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERS_MORE_NGINX_MODULE}.tar.gz
wget -O echo-nginx-module.tgz https://github.com/openresty/echo-nginx-module/archive/v${ECHO_NGINX_MODULE}.tar.gz
wget http://people.freebsd.org/~osa/ngx_http_redis-${REDIS_NGINX_MODULE}.tar.gz
#wget -O redis2-nginx-module.tgz https://github.com/openresty/redis2-nginx-module/archive/v${REDIS2_NGINX_MODULE}.tar.gz
tar -xvzf ngx_http_redis-${REDIS_NGINX_MODULE}.tar.gz
tar -xvzf srcache-nginx-module.tgz
tar -xvzf ngx_devel_kit.tgz
tar -xvzf set-misc-nginx-module.tgz
tar -xvzf headers-more-nginx-module.tgz
tar -xvzf echo-nginx-module.tgz
#tar -xvzf redis2-nginx-module.tgz
git clone https://github.com/openresty/redis2-nginx-module.git

if [ ${OSVERSION} -eq 6 ];then
./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/etc/nginx/modules --with-openssl=./libressl-${LIBRESSL_VERSION} --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error_log --http-log-path=/var/log/nginx/access_log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nobody --group=nobody --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --add-dynamic-module=naxsi-${NAXSI_VERSION}/naxsi_src --with-file-aio --with-threads --with-stream --with-stream_ssl_module --with-http_slice_module  --with-compat --with-http_v2_module --with-http_geoip_module=dynamic --add-dynamic-module=ngx_pagespeed-release-${NPS_VERSION}-beta ${PS_NGX_EXTRA_FLAGS} --add-dynamic-module=/usr/local/rvm/gems/ruby-${MY_RUBY_VERSION}/gems/passenger-${PASSENGER_VERSION}/src/nginx_module --add-dynamic-module=ngx_brotli --add-dynamic-module=echo-nginx-module-${ECHO_NGINX_MODULE} --add-dynamic-module=headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE} --add-dynamic-module=ngx_http_redis-${REDIS_NGINX_MODULE} --add-dynamic-module=redis2-nginx-module --add-dynamic-module=srcache-nginx-module-${SRCACHE_NGINX_MODULE} --add-dynamic-module=ngx_devel_kit-${NGX_DEVEL_KIT} --add-dynamic-module=set-misc-nginx-module-${SET_MISC_NGINX_MODULE} --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic' --with-ld-opt="-Wl,-E -lrt"
else
./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/etc/nginx/modules --with-openssl=./libressl-${LIBRESSL_VERSION} --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error_log --http-log-path=/var/log/nginx/access_log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nobody --group=nobody --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --add-dynamic-module=naxsi-${NAXSI_VERSION}/naxsi_src --with-file-aio --with-threads --with-stream --with-stream_ssl_module --with-http_slice_module --with-compat --with-http_v2_module --with-http_geoip_module=dynamic --add-dynamic-module=ngx_pagespeed-release-${NPS_VERSION}-beta --add-dynamic-module=/usr/local/rvm/gems/ruby-${MY_RUBY_VERSION}/gems/passenger-${PASSENGER_VERSION}/src/nginx_module --add-dynamic-module=ngx_brotli --add-dynamic-module=echo-nginx-module-${ECHO_NGINX_MODULE} --add-dynamic-module=headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE} --add-dynamic-module=ngx_http_redis-${REDIS_NGINX_MODULE} --add-dynamic-module=redis2-nginx-module --add-dynamic-module=srcache-nginx-module-${SRCACHE_NGINX_MODULE} --add-dynamic-module=ngx_devel_kit-${NGX_DEVEL_KIT} --add-dynamic-module=set-misc-nginx-module-${SET_MISC_NGINX_MODULE} --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic' --with-ld-opt="-Wl,-E"
fi
make DESTDIR=$(pwd)/tempostrip install
strip --strip-debug ./tempostrip/usr/sbin/nginx
rsync -a tempostrip/usr/sbin ../nginx-pkg/usr/
#strip --strip-debug ./tempo/etc/nginx/modules/*.so
if [ ${OSVERSION} -eq 6 ];then
./configure --with-debug --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/etc/nginx/modules --with-openssl=./libressl-${LIBRESSL_VERSION} --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error_log --http-log-path=/var/log/nginx/access_log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nobody --group=nobody --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --add-dynamic-module=naxsi-${NAXSI_VERSION}/naxsi_src --with-file-aio --with-threads --with-stream --with-stream_ssl_module --with-http_slice_module  --with-compat --with-http_v2_module --with-http_geoip_module=dynamic --add-dynamic-module=ngx_pagespeed-release-${NPS_VERSION}-beta ${PS_NGX_EXTRA_FLAGS} --add-dynamic-module=/usr/local/rvm/gems/ruby-${MY_RUBY_VERSION}/gems/passenger-${PASSENGER_VERSION}/src/nginx_module --add-dynamic-module=ngx_brotli --add-dynamic-module=echo-nginx-module-${ECHO_NGINX_MODULE} --add-dynamic-module=headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE} --add-dynamic-module=ngx_http_redis-${REDIS_NGINX_MODULE} --add-dynamic-module=redis2-nginx-module --add-dynamic-module=srcache-nginx-module-${SRCACHE_NGINX_MODULE} --add-dynamic-module=ngx_devel_kit-${NGX_DEVEL_KIT} --add-dynamic-module=set-misc-nginx-module-${SET_MISC_NGINX_MODULE} --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic' --with-ld-opt="-Wl,-E -lrt"
else
./configure --with-debug --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/etc/nginx/modules --with-openssl=./libressl-${LIBRESSL_VERSION} --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error_log --http-log-path=/var/log/nginx/access_log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nobody --group=nobody --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-http_auth_request_module --add-dynamic-module=naxsi-${NAXSI_VERSION}/naxsi_src --with-file-aio --with-threads --with-stream --with-stream_ssl_module --with-http_slice_module --with-compat --with-http_v2_module --with-http_geoip_module=dynamic --add-dynamic-module=ngx_pagespeed-release-${NPS_VERSION}-beta --add-dynamic-module=/usr/local/rvm/gems/ruby-${MY_RUBY_VERSION}/gems/passenger-${PASSENGER_VERSION}/src/nginx_module --add-dynamic-module=ngx_brotli --add-dynamic-module=echo-nginx-module-${ECHO_NGINX_MODULE} --add-dynamic-module=headers-more-nginx-module-${HEADERS_MORE_NGINX_MODULE} --add-dynamic-module=ngx_http_redis-${REDIS_NGINX_MODULE} --add-dynamic-module=redis2-nginx-module --add-dynamic-module=srcache-nginx-module-${SRCACHE_NGINX_MODULE} --add-dynamic-module=ngx_devel_kit-${NGX_DEVEL_KIT} --add-dynamic-module=set-misc-nginx-module-${SET_MISC_NGINX_MODULE} --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic' --with-ld-opt="-Wl,-E"
fi
make DESTDIR=$(pwd)/tempo install
rsync -a tempo/usr/sbin/nginx ../nginx-pkg/usr/sbin/nginx-debug


git clone https://github.com/nbs-system/naxsi-rules.git
rsync -a naxsi-rules/*.rules ../nginx-module-naxsi-pkg/etc/nginx/naxsi.d/
rsync -a naxsi-${NAXSI_VERSION}/naxsi_config/naxsi_core.rules ../nginx-module-naxsi-pkg/etc/nginx/naxsi.d/naxsi_core.rules
rsync -a naxsi-${NAXSI_VERSION}/nxapi ../nginx-module-naxsi-pkg/usr/nginx/
rsync -a ../nxapi.json ../nginx-module-naxsi-pkg/usr/nginx/nxapi/
rsync -a ../nginx-pkg-64-common/etc/nginx/fastcgi_params_geoip ../nginx-module-geoip-pkg/etc/nginx/
rsync -a ../nginx-pkg-64-common/etc/nginx/conf.d/pagespeed.conf ../nginx-module-pagespeed-pkg/etc/nginx/conf.d/
rsync -a ../nginx-pkg-64-common/etc/nginx/conf.d/pagespeed_passthrough.conf ../nginx-module-pagespeed-pkg/etc/nginx/conf.d/
rsync -a ../nginx-pkg-64-common/etc/nginx/conf.d/brotli.conf ../nginx-module-brotli-pkg/etc/nginx/conf.d/
rsync -a ../nginx-pkg-64-common/etc/nginx/conf.d/naxsi_* ../nginx-module-naxsi-pkg/etc/nginx/conf.d/
rsync -a tempo/usr/sbin ../nginx-pkg/usr/
for module in brotli geoip naxsi pagespeed passenger redis redis2 set_misc srcache_filter echo
do
  rsync -a tempo/etc/nginx/modules/ngx_http_${module}* ../nginx-module-${module}-pkg/etc/nginx/modules/
  rsync -a ../nginx-pkg-64-common/etc/nginx/conf.auto/${module}.conf ../nginx-module-${module}-pkg/etc/nginx/conf.auto/
  rsync -a ../nginx-pkg-64-common/etc/nginx/modules.d/${module}.load ../nginx-module-${module}-pkg/etc/nginx/modules.d/
done
rsync -a tempo/etc/nginx/modules/ngx_pagespeed.so ../nginx-module-pagespeed-pkg/etc/nginx/modules/
rsync -a tempo/etc/nginx/modules/ndk_http_module.so ../nginx-pkg/etc/nginx/modules/
rsync -a ../nginx-pkg-64-common/etc/nginx/modules.d/ndk.load ../nginx-pkg/etc/nginx/modules.d/
rsync -a tempo/etc/nginx/modules/ngx_http_headers_more_filter_module.so ../nginx-pkg/etc/nginx/modules/
rsync -a ../nginx-pkg-64-common/etc/nginx/modules.d/headers_more_filter.load ../nginx-pkg/etc/nginx/modules.d/

rsync -a ../nginx-pkg-64-common/usr/nginx/scripts/nginx-passenger* ../nginx-module-passenger-pkg/usr/nginx/scripts/
rsync -a ../nginx-pkg-64-common/usr/nginx/scripts/nxapi* ../nginx-module-naxsi-pkg/usr/nginx/scripts/
#We remove redis2 from redis package which gets copied due to file glob
rm -f ../nginx-module-redis-pkg/etc/nginx/modules/ngx_http_redis2_module.so

sed -i "s/RUBY_VERSION/$MY_RUBY_VERSION/g" ../nginx-module-passenger-pkg/etc/nginx/conf.auto/passenger.conf
sed -i "s/PASSENGER_VERSION/$PASSENGER_VERSION/g" ../nginx-module-passenger-pkg/etc/nginx/conf.auto/passenger.conf
sed -i "s/RUBY_VERSION/$MY_RUBY_VERSION/g" ../nginx-module-passenger-pkg/usr/nginx/scripts/nginx-passenger-setup.sh
sed -i "s/PASSENGER_VERSION/$PASSENGER_VERSION/g" ../nginx-module-passenger-pkg/usr/nginx/scripts/nginx-passenger-setup.sh

rsync -a /usr/local/rvm/gems/ruby-${MY_RUBY_VERSION}/gems/passenger-${PASSENGER_VERSION}/buildout ../nginx-module-passenger-pkg/usr/nginx/
cd ../nginx-pkg

fpm -s dir -t rpm -C ../nginx-pkg --vendor "Anoop P Alias" --version ${NGINX_VERSION} --iteration ${NGINX_RPM_ITER} -a $(arch) -m anoopalias01@gmail.com -e --description "nDeploy custom nginx package" --url http://anoopalias.github.io/XtendWeb/ --conflicts nginx -d zlib -d pcre -d libcurl --after-install ../after_nginx_install --before-remove ../after_nginx_uninstall --name nginx-nDeploy .
rsync -a nginx-nDeploy-* root@gnusys.net:/usr/share/nginx/html/CentOS/${OSVERSION}/x86_64/

for module in brotli geoip naxsi pagespeed passenger redis redis2 set_misc srcache_filter echo
do
  cd ../nginx-module-${module}-pkg
  if [ ${module} == "brotli" ];then
    fpm -s dir -t rpm -C ../nginx-module-${module}-pkg --vendor "Anoop P Alias" --version ${NGINX_VERSION} --iteration ${NGINX_RPM_ITER} -a $(arch) -m anoopalias01@gmail.com -e --description "nDeploy custom nginx-${module} package" --url http://anoopalias.github.io/XtendWeb/ --conflicts nginx-module-${module} -d libbrotli-nDeploy --name nginx-nDeploy-module-${module} .
  elif [ ${module} == "geoip" ];then
    fpm -s dir -t rpm -C ../nginx-module-${module}-pkg --vendor "Anoop P Alias" --version ${NGINX_VERSION} --iteration ${NGINX_RPM_ITER} -a $(arch) -m anoopalias01@gmail.com -e --description "nDeploy custom nginx-${module} package" --url http://anoopalias.github.io/XtendWeb/ --conflicts nginx-module-${module} -d GeoIP --name nginx-nDeploy-module-${module} .
  elif [ ${module} == "pagespeed" ];then
    fpm -s dir -t rpm -C ../nginx-module-${module}-pkg --vendor "Anoop P Alias" --version ${NGINX_VERSION} --iteration ${NGINX_RPM_ITER} -a $(arch) -m anoopalias01@gmail.com -e --description "nDeploy custom nginx-${module} package" --url http://anoopalias.github.io/XtendWeb/ --conflicts nginx-module-${module} -d memcached --name nginx-nDeploy-module-${module} .
  else
    fpm -s dir -t rpm -C ../nginx-module-${module}-pkg --vendor "Anoop P Alias" --version ${NGINX_VERSION} --iteration ${NGINX_RPM_ITER} -a $(arch) -m anoopalias01@gmail.com -e --description "nDeploy custom nginx-${module} package" --url http://anoopalias.github.io/XtendWeb/ --conflicts nginx-module-${module} --name nginx-nDeploy-module-${module} .
  fi
  rsync -a nginx-nDeploy-* root@gnusys.net:/usr/share/nginx/html/CentOS/${OSVERSION}/x86_64/
done
