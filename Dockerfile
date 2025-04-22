FROM quay.io/curl/curl:latest
USER 0
RUN apk add --no-cache tini jq
COPY entry.sh /
ENTRYPOINT ["tini", "-g", "--"]
CMD ["/entry.sh"]
