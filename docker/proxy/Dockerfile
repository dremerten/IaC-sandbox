FROM alpine:3.19
RUN apk add --no-cache socat \
  && adduser -D -u 1000 sandbox
USER 1000:1000
ENTRYPOINT ["socat","TCP-LISTEN:5446,fork,reuseaddr","TCP:sandbox:5446"]
