FROM ubuntu:xenial as builder

MAINTAINER NGINX Docker Maintainers "docker-maint@nginx.com"

ENV NGINX_VERSION=1.12.1
ENV TZ='Europe/Moscow'

RUN GPG_KEYS=B0F4253373F8F6F510D42178520A9993A1C052F8 \
    && CONFIG="\
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --http-client-body-temp-path=/var/cache/nginx/client_temp \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_stub_status_module \
    --with-http_auth_request_module \
    --with-http_xslt_module=dynamic \
    --with-http_image_filter_module=dynamic \
    --with-http_geoip_module=dynamic \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-stream_realip_module \
    --with-stream_geoip_module=dynamic \
    --with-http_slice_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-compat \
    --with-file-aio \
    --with-http_v2_module \
    --add-module=nginx-limit-upstream \
    " \
    && addgroup --system nginx \
    && adduser --disabled-login --system --home /var/cache/nginx --shell /sbin/nologin --ingroup nginx nginx \
    && apt-get update && apt-get install -y \
    curl \
    patch \
    git \
    build-essential \
    libexpat-dev \
    libgd-dev \
    libgeoip-dev \
    libmhash-dev \
    libpam0g-dev \
    libpcre3-dev \
    libperl-dev \
    libssl-dev \
    libxslt1-dev \
    zlib1g-dev \
    tzdata \
    && curl -fSL http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o nginx.tar.gz \
    && mkdir -p /usr/src \
    && tar -zxC /usr/src -f nginx.tar.gz \
    && rm nginx.tar.gz \
    && cd /usr/src/nginx-$NGINX_VERSION \
    && git clone --depth 1 --branch haosdent/nginx-1.12.1 https://github.com/haosdent/nginx-limit-upstream.git \
    && patch -p1 < nginx-limit-upstream/nginx-1.12.1.patch \
    && ./configure $CONFIG \
    && make -j$(getconf _NPROCESSORS_ONLN)

FROM ubuntu:xenial
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx.vh.default.conf /etc/nginx/conf.d/default.conf
RUN  apt-get update && apt-get install -y \
    libexpat1 \
    libgd3 \
    libgeoip1 \
    libmhash2 \
    libpam0g \
    libpcre3 \
    libperl5.22 \
    libssl1.0.0 \
    libxslt1.1 \
    zlib1g 
COPY --from=builder /usr/src/nginx-1.12.1/conf /etc/nginx
COPY --from=builder /usr/src/nginx-1.12.1/objs/nginx /usr/sbin/
COPY --from=builder /usr/src/nginx-1.12.1/objs/*.so /usr/lib/nginx/modules/
RUN mkdir -p /var/log/nginx/ && touch /var/log/nginx/error.log
RUN  addgroup --system nginx \
    && adduser --disabled-login --system --home /var/cache/nginx --shell /sbin/nologin --ingroup nginx nginx \
    && chown -R nginx:nginx /var/log/nginx/
EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]