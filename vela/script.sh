#!/bin/sh
echo "
[common]
server_addr = ${server_addr}
server_port = ${server_port}

[${connect_name}]
type = tcp
local_ip = ${local_ip}
local_port = ${local_port}
remote_port = ${remote_port}
" > frpc.ini

/usr/bin/frpc -c /frpc.ini