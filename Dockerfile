FROM ruby:2.5.1-stretch

RUN \
  set -ex \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install \
    -y \
    --no-install-recommends \
    locales \
  && sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen \
  && dpkg-reconfigure --frontend=noninteractive locales \
  && update-locale LANG=en_GB.UTF-8

ENV \
  LANG=en_GB.UTF-8 \
  LANGUAGE=en_GB.UTF-8 \
  LC_ALL=en_GB.UTF-8

ARG VERSION_NUMBER
ARG COMMIT_ID
ARG BUILD_DATE
ARG BUILD_TAG

ENV APPVERSION=${VERSION_NUMBER}
ENV APP_GIT_COMMIT=${COMMIT_ID}
ENV APP_BUILD_DATE=${BUILD_DATE}
ENV APP_BUILD_TAG=${BUILD_TAG}

WORKDIR /app

RUN \
  set -ex \
  && apt-get install \
    -y \
    --no-install-recommends \
    apt-transport-https \
    build-essential \
    libpq-dev \
    netcat \
    nodejs \
  && timedatectl set-timezone Europe/London || true \
  && gem update bundler --no-document

RUN \
  set -ex \
  && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN \
  set -ex \
  && apt-get update \
  && apt-get install \
    -y \
    --no-install-recommends \
    yarn=1.10.1-1

COPY Gemfile Gemfile.lock package.json ./

RUN bundle install --without development test --jobs 2 --retry 3
COPY . /app
RUN RAILS_ENV=production rails assets:precompile
