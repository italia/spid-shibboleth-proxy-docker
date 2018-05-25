FROM node:alpine
RUN apk --update add gettext
COPY docker-bootstrap.sh /usr/local/bin/
WORKDIR /src/app
COPY . .
RUN npm install
EXPOSE 8080
CMD ["docker-bootstrap.sh"]
