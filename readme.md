# Shipyard LB

This provides the Shipyard Load Balancer for production deployment.  It uses
the OpenResty Nginx build.

* `docker build -t shipyard-lb .`
* `docker run shipyard-lb`

Ports

* 80
* 443

Environment Variables

* `APP_ROUTER_UPSTREAMS`: List of Shipyard App Routers (space separated host:port pairs)
* `REDIS_HOST`: Shipyard Redis Host
* `REDIS_PORT`: Shipyard Redis Port
* `NGINX_RESOLVER`: DNS resolver for Nginx (default: system dns)
* `SSL_CERT_PATH`: SSL certificate file to be used
* `SSL_KEY_PATH`: SSL key file to be used
* `FORCE_HTTPS`: Force all traffic to HTTPS (default: false)

Example using SSL and forcing traffic to HTTPS:

`docker run -i -t -d -p 80:80 -p 443:443 -v /opt/ssl:/opt/ssl -e SSL_CERT_PATH=/opt/ssl/ssl.cer -e SSL_KEY_PATH=/opt/ssl/ssl.key -e FORCE_HTTPS=true --link shipyard_redis:redis --link shipyard_router:app_router --name shipyard_lb shipyard/lb`
