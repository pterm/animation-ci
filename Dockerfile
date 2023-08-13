# Use latest alpine image as base
FROM golang:alpine

# Copy needed stuff into container
COPY LICENSE README.md /
COPY entrypoint.sh /entrypoint.sh

# Install some packages
RUN apk add jq bash git nodejs npm asciinema sudo
RUN apk add --no-cache --upgrade grep
RUN apk --no-cache add findutils

# Start action
ENTRYPOINT ["/entrypoint.sh"]
