#!/bin/bash
HTTP_PORT=80
HTTPS_PORT=443
REDIS_HOST=${REDIS_PORT_6379_TCP_ADDR:-$REDIS_HOST}
REDIS_HOST=${REDIS_HOST:-127.0.0.1}
REDIS_PORT=${REDIS_PORT_6379_TCP_PORT:-$REDIS_PORT}
REDIS_PORT=${REDIS_PORT:-6379}
SSL_CERT_PATH=${SSL_CERT_PATH:-}
SSL_KEY_PATH=${SSL_KEY_PATH:-}
LOG_DIR=/var/log/shipyard
NGINX_RESOLVER=${NGINX_RESOLVER:-`cat /etc/resolv.conf | grep ^nameserver | head -1 | awk '{ print $2; }'`}
APP_ROUTER_UPSTREAMS=${APP_ROUTER_UPSTREAMS:-127.0.0.1:8001}
mkdir -p $LOG_DIR
NGINX_CONF=/etc/shipyard.conf
ROUTER_CFG=""

# check for fig env
if [ ! -z "$SHIPYARD_REDIS_1_PORT_6379_TCP_ADDR" ]; then
    REDIS_HOST=$SHIPYARD_REDIS_1_PORT_6379_TCP_ADDR
    REDIS_PORT=$SHIPYARD_REDIS_1_PORT_6379_TCP_PORT
    APP_ROUTER_UPSTREAMS=$SHIPYARD_ROUTER_1_PORT_80_TCP_ADDR:$SHIPYARD_ROUTER_1_PORT_80_TCP_PORT
fi

# check for router link
if [ ! -z "$APP_ROUTER_PORT_80_TCP_ADDR" ] ; then
    APP_ROUTER_UPSTREAMS="${APP_ROUTER_PORT_80_TCP_ADDR}:${APP_ROUTER_PORT_80_TCP_PORT}"
fi

for H in $APP_ROUTER_UPSTREAMS
do
    ROUTER_CFG="$ROUTER_CFG    server $H;"
done
# nginx
cat << EOF > $NGINX_CONF
daemon off;
worker_processes  1;
error_log $LOG_DIR/nginx_error.log;

events {
  worker_connections 1024;
}

http {

  upstream app_router {
    $ROUTER_CFG
  }

  server {
    listen $HTTP_PORT;
EOF

# ssl
if [ ! -z "$SSL_CERT_PATH" ] && [ ! -z "$SSL_KEY_PATH" ] ; then
    cat << EOF >> $NGINX_CONF
    listen $HTTPS_PORT ssl;
    ssl_certificate $SSL_CERT_PATH;
    ssl_certificate_key $SSL_KEY_PATH;
EOF
fi

cat << EOF >> $NGINX_CONF
    access_log $LOG_DIR/nginx_access.log;
    client_max_body_size 0;

    location / {
      proxy_pass http://app_router;
      proxy_set_header Host \$http_host;
      proxy_set_header X-Forwarded-Host \$host;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header X-Scheme \$scheme;
      proxy_set_header X-Forwarded-Protocol \$scheme;
    }

    location /console/ {
      resolver $NGINX_RESOLVER;

      set \$target '';
      rewrite_by_lua '
        local session_id = " "
        local match, err = ngx.re.match(ngx.var.uri, "(/console/(?<id>.*)/)")
        if match then
            session_id = match["id"]
        else
            if err then
                ngx.log(ngx.ERR, "error: ", err)
                return
            end
            ngx.say("url malformed")
        end

        local key = "console:" .. session_id

        local redis = require "resty.redis"
        local red = redis:new()

        red:set_timeout(1000) -- 1 second

        local ok, err = red:connect("$REDIS_HOST", $REDIS_PORT)
        if not ok then
            ngx.log(ngx.ERR, "failed to connect to redis: ", err)
            return ngx.exit(500)
        end

        local console, err = red:hmget(key, "host", "path")
        if not console then
            ngx.log(ngx.ERR, "failed to get redis key: ", err)
            return ngx.exit(500)
        end

        if console == ngx.null then
            ngx.log(ngx.ERR, "no console session found for key ", key)
            return ngx.exit(400)
        end

        ngx.var.target = console[1]
        
        ngx.req.set_uri(console[2])
      ';
 
      
      proxy_pass http://\$target;
      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_read_timeout 7200s;
    }
  }
}
EOF
/usr/local/openresty/nginx/sbin/nginx -p /usr/local/openresty/nginx -c /etc/shipyard.conf
