module github.com/leishi1313/net-traffic-exporter

go 1.15

require (
	github.com/go-delve/delve v1.5.0 // indirect
	github.com/jessevdk/go-flags v1.4.0
	github.com/mitchellh/gox v1.0.1 // indirect
	github.com/prometheus/client_golang v1.7.1
	github.com/sirupsen/logrus v1.6.0
	golang.org/x/net v0.0.0-20200904194848-62affa334b73
	golang.org/x/text v0.3.3 // indirect
	google.golang.org/grpc v1.32.0
	v2ray.com/core v4.19.1+incompatible
)

replace v2ray.com/core => github.com/v2ray/v2ray-core v1.24.5-0.20200610141238-f9935d0e93ea
