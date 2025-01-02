FROM nginx:alpine
COPY index.html /usr/share/nginx/html
COPY styles.css /usr/share/nginx/html
COPY script.js.template /usr/share/nginx/html
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
CMD ["/entrypoint.sh"]