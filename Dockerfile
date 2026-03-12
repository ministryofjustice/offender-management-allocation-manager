FROM ruby:3.4.9-alpine3.23 AS base

# Increment to bust Docker layer cache
ENV DOCKER_CACHE_BUSTER=1

ENV \
  LANG=C.UTF-8 \
  LC_ALL=C.UTF-8 \
  TZ=Europe/London \
  BUNDLE_DEPLOYMENT=1 \
  BUNDLE_WITHOUT=development:test \
  BUNDLE_PATH=/app/vendor/bundle

WORKDIR /app

FROM base AS builder

# Build-only dependencies required for native gems.
RUN apk add --no-cache \
    build-base \
    ca-certificates \
    nodejs \
    postgresql-dev \
    tzdata \
    yaml-dev \
    yarn \
  && apk upgrade --no-cache zlib

RUN mkdir -p /tmp/rds-cert \
  && wget -qO /tmp/rds-cert/root.crt https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

COPY Gemfile* .ruby-version ./
RUN bundle config set deployment 'true' \
  && bundle install --jobs 4 --retry 3

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY . /app

RUN SECRET_KEY_BASE=key RAILS_ENV=production bundle exec rails assets:precompile --trace

FROM base AS runtime

RUN apk add --no-cache \
  ca-certificates \
  libcurl \
  postgresql-libs \
  tzdata \
  && apk upgrade --no-cache zlib

RUN addgroup -S appgroup -g 1001 \
  && adduser -S appuser -u 1001 -G appgroup -h /home/appuser

RUN mkdir -p /home/appuser/.postgresql

COPY --from=builder --chown=appuser:appgroup /app/vendor/bundle /app/vendor/bundle
COPY --from=builder --chown=appuser:appgroup /app/public /app/public
COPY --from=builder --chown=appuser:appgroup /tmp/rds-cert/root.crt /home/appuser/.postgresql/root.crt
COPY --chown=appuser:appgroup . /app

RUN mkdir -p /app/log /app/tmp \
  && chown -R appuser:appgroup /app/log /app/tmp /home/appuser

ARG BUILD_NUMBER
ARG GIT_BRANCH
ARG GIT_REF

ENV BUILD_NUMBER=${BUILD_NUMBER} \
  GIT_BRANCH=${GIT_BRANCH} \
  GIT_REF=${GIT_REF}

USER 1001
