#!/usr/bin/env bash

wget https://github.com/fatedier/frp/releases/download/v0.43.0/frp_0.43.0_linux_amd64.tar.gz
tar xzf frp_0.43.0_linux_amd64.tar.gz
cd frp_0.43.0_linux_amd64

echo "# frps.ini
[common]
bind_addr = 0.0.0.0
bind_port = 9090
vhost_http_port = 8080

dashboard_addr = 0.0.0.0
dashboard_port = 9091
dashboard_user = admin
dashboard_pwd = vela123
" >> frps.ini

nohup ./frps >./frps.log 2>&1 &

