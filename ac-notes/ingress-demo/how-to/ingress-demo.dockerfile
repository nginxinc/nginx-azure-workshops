FROM nginxinc/ingress-demo:latest
ADD file:ec475c2abb2d46435286b5ae5efacf5b50b1a9e3b6293b69db3c0172b5b9658b in /
CMD ["/bin/sh"]
LABEL maintainer=NGINX Docker Maintainers <docker-maint@nginx.com>
ENV NGINX_VERSION=1.19.6
ENV NJS_VERSION=0.5.0
ENV PKG_RELEASE=1
RUN /bin/sh -c set -x     \
    && addgroup -g 101 -S nginx     \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx     \
    && apkArch="$(cat /etc/apk/arch)"     \
    && nginxPackages="         nginx=${NGINX_VERSION}-r${PKG_RELEASE}         nginx-module-xslt=${NGINX_VERSION}-r${PKG_RELEASE}         nginx-module-geoip=${NGINX_VERSION}-r${PKG_RELEASE}         nginx-module-image-filter=${NGINX_VERSION}-r${PKG_RELEASE}         nginx-module-njs=${NGINX_VERSION}.${NJS_VERSION}-r${PKG_RELEASE}     "     \
    && case "$apkArch" in         x86_64)             set -x             \
    && KEY_SHA512="e7fa8303923d9b95db37a77ad46c68fd4755ff935d0a534d26eba83de193c76166c68bfe7f65471bf8881004ef4aa6df3e34689c305662750c0172fca5d8552a *stdin"             \
    && apk add --no-cache --virtual .cert-deps                 openssl             \
    && wget -O /tmp/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub             \
    && if [ "$(openssl rsa -pubin -in /tmp/nginx_signing.rsa.pub -text -noout | openssl sha512 -r)" = "$KEY_SHA512" ]; then                 echo "key verification succeeded!";                 mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/;             else                 echo "key verification failed!";                 exit 1;             fi             \
    && apk del .cert-deps             \
    && apk add -X "https://nginx.org/packages/mainline/alpine/v$(egrep -o '^[0-9]+\.[0-9]+' /etc/alpine-release)/main" --no-cache $nginxPackages             ;;         *)             set -x             \
    && tempDir="$(mktemp -d)"             \
    && chown nobody:nobody $tempDir             \
    && apk add --no-cache --virtual .build-deps                 gcc                 libc-dev                 make                 openssl-dev                 pcre-dev                 zlib-dev                 linux-headers                 libxslt-dev                 gd-dev                 geoip-dev                 perl-dev                 libedit-dev                 mercurial                 bash                 alpine-sdk                 findutils             \
    && su nobody -s /bin/sh -c "                 export HOME=${tempDir}                 \
    && cd ${tempDir}                 \
    && hg clone https://hg.nginx.org/pkg-oss                 \
    && cd pkg-oss                 \
    && hg up ${NGINX_VERSION}-${PKG_RELEASE}                 \
    && cd alpine                 \
    && make all                 \
    && apk index -o ${tempDir}/packages/alpine/${apkArch}/APKINDEX.tar.gz ${tempDir}/packages/alpine/${apkArch}/*.apk                 \
    && abuild-sign -k ${tempDir}/.abuild/abuild-key.rsa ${tempDir}/packages/alpine/${apkArch}/APKINDEX.tar.gz                 "             \
    && cp ${tempDir}/.abuild/abuild-key.rsa.pub /etc/apk/keys/             \
    && apk del .build-deps             \
    && apk add -X ${tempDir}/packages/alpine/ --no-cache $nginxPackages             ;;     esac     \
    && if [ -n "$tempDir" ]; then rm -rf "$tempDir"; fi     \
    && if [ -n "/etc/apk/keys/abuild-key.rsa.pub" ]; then rm -f /etc/apk/keys/abuild-key.rsa.pub; fi     \
    && if [ -n "/etc/apk/keys/nginx_signing.rsa.pub" ]; then rm -f /etc/apk/keys/nginx_signing.rsa.pub; fi     \
    && apk add --no-cache --virtual .gettext gettext     \
    && mv /usr/bin/envsubst /tmp/         \
    && runDeps="$(         scanelf --needed --nobanner /tmp/envsubst             | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }'             | sort -u             | xargs -r apk info --installed             | sort -u     )"     \
    && apk add --no-cache $runDeps     \
    && apk del .gettext     \
    && mv /tmp/envsubst /usr/local/bin/     \
    && apk add --no-cache tzdata     \
    && apk add --no-cache curl ca-certificates     \
    && ln -sf /dev/stdout /var/log/nginx/access.log     \
    && ln -sf /dev/stderr /var/log/nginx/error.log     \
    && mkdir /docker-entrypoint.d
COPY file:e7e183879c35719c18aa7f733651029fbcc55f5d8c22a877ae199b389425789e in /
COPY file:0b866ff3fc1ef5b03c4e6c8c513ae014f691fb05d530257dfffd07035c1b75da in /docker-entrypoint.d
COPY file:0fd5fca330dcd6a7de297435e32af634f29f7132ed0550d342cad9fd20158258 in /docker-entrypoint.d
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 80
STOPSIGNAL SIGQUIT
CMD ["nginx" "-g" "daemon off;"]
LABEL maintainer=Matt Kryshak <matt.kryshak@nginx.com>
COPY dir:2b12785b6c5bb3bd64cae65160474ac0551e5386c0a63b8d7641690929ead46b in /etc/nginx/certs
COPY file:18eeef63b2c049fbd6dec94ce631ce791ca3ab3483b671fb2881b58407d4d6a9 in /etc/nginx/conf.d/default.conf
COPY file:7220b420c5a891cbe1d5b2dd693475149c929dda54267422f558c9920ce170af in /etc/nginx/nginx.conf
COPY dir:d63e44efdbba5d80aef30b0d7405800143e6a4e92c0bc9f962be4296e0df4418 in /usr/share/nginx
EXPOSE 443 80
CMD ["nginx" "-g" "daemon off;"]
