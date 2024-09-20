#!/bin/bash

docker run -v ./html:/var/www/html:ro -v ./default:/etc/nginx/conf.d/default.conf:ro -p 8081:80 nginx
