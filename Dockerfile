FROM ruby:3.2.2-slim-bullseye

# Incremenent to bust Docker layer cache
ENV DOCKER_CACHE_BUSTER=1

ARG VERSION_NUMBER
ARG COMMIT_ID
ARG BUILD_DATE
ARG BUILD_TAG

RUN mkdir -p /home/appuser && \
  useradd appuser -u 1001 --user-group --home /home/appuser && \
  chown -R appuser:appuser /home/appuser

RUN \
  set -ex \
  && mkdir -p /etc/apt/keyrings \
  && apt-get update \
  && apt-get full-upgrade -y --no-install-recommends \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends locales \
  && sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen \
  && dpkg-reconfigure --frontend=noninteractive locales \
  && update-locale LANG=en_GB.UTF-8 \
  && apt-get clean

ENV \
  LANG=en_GB.UTF-8 \
  LANGUAGE=en_GB.UTF-8 \
  LC_ALL=en_GB.UTF-8

WORKDIR /app

RUN \
  set -ex \
  && apt-get install \
    -y \
    --no-install-recommends \
    curl \
    build-essential \
    libpq-dev \
    postgresql-client \
    libjemalloc-dev \
    unzip \
    ca-certificates \
    gnupg \
  && timedatectl set-timezone Europe/London || true \
  && gem install bundler -v 2.2.29 --no-document \
  && apt-get clean

# Install official AWS CLI
RUN \
  set -ex \
  && touch /tmp/without-this-curl-does-not-write-to-tmp-for-some-reason \
  && curl -s 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o /tmp/awscliv2.zip \
  && unzip -qd /tmp/awscliv2 /tmp/awscliv2.zip \
  && /tmp/awscliv2/aws/install

# Install Node.js and Yarn
RUN set -ex ; \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
        gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_16.x nodistro main" | \
        tee /etc/apt/sources.list.d/nodesource_nodejs16.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && apt-get clean \
    && npm --global install yarn

# Highly cachable layers. These statements are rarely expected to invalidate the cache.

# Install Ruby and Node dependencies
COPY Gemfile Gemfile.lock package.json ./
RUN yarn install \
    && bundle config set --local without 'development test' \
    && bundle install --jobs 2 --retry 3

# Non-cacheable layers. Everything below here is expected to change with every commit

ENV APPVERSION=${VERSION_NUMBER}
ENV APP_GIT_COMMIT=${COMMIT_ID}
ENV APP_BUILD_DATE=${BUILD_DATE}
ENV APP_BUILD_TAG=${BUILD_TAG}

COPY . /app

RUN chown -R appuser:appuser /app

USER 1001

RUN RAILS_ENV=production rails assets:precompile
