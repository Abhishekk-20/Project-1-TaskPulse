FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
RUN npm run build

FROM nginx:1.28-alpine
COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=builder /app/dist /usr/share/nginx/html
RUN mkdir -p /tmp/nginx/client_temp /tmp/nginx/proxy_temp /tmp/nginx/fastcgi_temp /tmp/nginx/uwsgi_temp /tmp/nginx/scgi_temp \
    && rm -f /etc/nginx/conf.d/default.conf \
    && chown -R 101:101 /tmp/nginx /usr/share/nginx/html
USER 101:101
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
