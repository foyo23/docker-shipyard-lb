FROM ubuntu:12.04
MAINTAINER Shipyard Project "http://shipyard-project.com"
RUN apt-get -qq update
RUN apt-get install -y libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make wget
RUN wget http://openresty.org/download/ngx_openresty-1.4.3.3.tar.gz -O /tmp/nginx.tar.gz
RUN (cd /tmp && tar zxf nginx.tar.gz)
RUN (cd /tmp/ngx_* && ./configure --with-luajit)
RUN (cd /tmp/ngx_* && make install)
ADD run.sh /usr/local/bin/run
VOLUME /var/log/shipyard
EXPOSE 80
EXPOSE 443
CMD ["/bin/sh", "-e", "/usr/local/bin/run"]
