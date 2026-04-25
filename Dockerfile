FROM ruby:3.2.10-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git libsqlite3-dev libyaml-dev \
    && rm -rf /var/lib/apt/lists/*

RUN gem install bundler -v 2.5.22

WORKDIR /app
