FROM ubuntu:xenial as rtmp-build
#FROM debian:stretch-slim

RUN apt-get update -y
RUN apt-get install -y software-properties-common wget git
RUN add-apt-repository ppa:nginx/development
RUN sed -i "s/# deb-src/deb-src/" /etc/apt/sources.list.d/nginx-ubuntu-development-xenial.list
RUN apt-get update -y
RUN apt-get install -y dpkg-dev
RUN apt-get install -y libexpat-dev libgd-dev libgeoip-dev libhiredis-dev libluajit-5.1-dev libmhash-dev libpam0g-dev libpcre3-dev libperl-dev libssl-dev libxslt1-dev po-debconf quilt zlib1g-dev debhelper
RUN apt-get source nginx
RUN cd /usr/src && \
    wget https://github.com/winshining/nginx-http-flv-module/archive/v1.2.5.tar.gz && \
    tar -xzf v1.2.5.tar.gz && \
    git clone https://salsa.debian.org/nginx-team/nginx.git && \
    sed -i "s/full_configure_flags := \\\\/full_configure_flags := --add-module=\/usr\/src\/nginx-http-flv-module-1.2.5 \\\\/" nginx/debian/rules
RUN cd /usr/src/nginx && \
    dpkg-buildpackage -b -d

# Stream RTMP server
FROM ubuntu:xenial
WORKDIR /root/
COPY --from=rtmp-build /usr/src/*.deb ./
RUN apt-get update -y && \
    apt-get install -y libxml2 libgeoip1 libxslt1.1 libgd3 libssl1.0.0 && \
    dpkg --install nginx-common*.deb \
		   libnginx-mod-rtmp*.deb \
                   libnginx-mod-http-auth-pam*.deb \
		   libnginx-mod-http-dav-ext*.deb \
		   libnginx-mod-http-echo*.deb \
		   libnginx-mod-http-geoip*.deb \
		   libnginx-mod-http-image-filter*.deb \
		   libnginx-mod-http-subs-filter*.deb \
		   libnginx-mod-http-upstream-fair*.deb \
		   libnginx-mod-http-xslt-filter*.deb \
		   libnginx-mod-stream*.deb \
		   libnginx-mod-mail*.deb && \
    dpkg --install nginx-full*.deb && \
    rm *.deb && \
    rm /etc/nginx/modules-enabled/50-mod-rtmp.conf
COPY nginx/rtmp.conf /etc/nginx/conf.d/
COPY nginx/nginx.conf /etc/nginx/

CMD /usr/sbin/nginx -g "daemon off;"
