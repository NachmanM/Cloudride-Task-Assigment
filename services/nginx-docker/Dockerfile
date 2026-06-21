FROM nginx

COPY index.html /usr/share/nginx/html/index.html.template

ENV API_BASE_URL=/api

ENTRYPOINT ["/bin/sh", "-c", "envsubst '${API_BASE_URL}' < /usr/share/nginx/html/index.html.template > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'"]
