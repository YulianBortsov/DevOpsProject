#!/bin/sh
envsubst < /usr/share/nginx/html/script.js.template > /usr/share/nginx/html/script.js
nginx -g 'daemon off;'