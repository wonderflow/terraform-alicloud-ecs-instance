#!/bin/sh
echo "
[common]
server_addr = ${server_addr}
server_port = ${server_port}

[web]
type = tcp
local_ip = 127.0.0.1
local_port = ${local_port}
remote_port = ${remote_port}
" > frpc.ini

/usr/bin/frpc -c /frpc.ini