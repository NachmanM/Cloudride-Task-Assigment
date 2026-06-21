FROM nginx

COPY index.html /usr/share/nginx/html/index.html.template
COPY nginx.conf.template /etc/nginx/conf.d/default.conf.template

ENV API_BASE_URL=""
ENV API_URL=api-service.local

ENTRYPOINT ["/bin/sh", "-c", "envsubst '${API_BASE_URL}' < /usr/share/nginx/html/index.html.template > /usr/share/nginx/html/index.html && envsubst '${API_URL}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
