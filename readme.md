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
