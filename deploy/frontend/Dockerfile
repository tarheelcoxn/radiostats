FROM node:lts-alpine as build

WORKDIR /app

ENV PATH /app/node_modules/.bin:$PATH

COPY frontend/package.json ./
COPY frontend/package-lock.json ./
RUN npm ci

COPY frontend ./
RUN npm run build

FROM nginx:alpine
RUN apk add bash && apk add yq-go
COPY --from=build /app/build /usr/share/nginx/html
COPY deploy/frontend/site.template /etc/nginx/conf.d/default.template
COPY deploy/frontend/env.sh ./
COPY deploy/frontend/start.sh ./
RUN chmod +x ./env.sh && chmod +x ./start.sh
CMD ./start.sh
