FROM nginx:1.27-alpine

COPY web/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY web/index.html web/app.js web/styles.css /usr/share/nginx/html/

ENV API_UPSTREAM=api:8080
EXPOSE 8080
