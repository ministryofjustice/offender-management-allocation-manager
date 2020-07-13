FROM ruby:2.6.3-stretch

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
    libjemalloc-dev \
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
    yarn=1.10.1-1 \
  && yarn install

COPY Gemfile Gemfile.lock package.json ./

RUN bundle install --without development test --jobs 2 --retry 3

# build msoffice-crypt and put it on the path
RUN \
  mkdir ./build \
  && cd ./build \
  && git clone https://github.com/herumi/cybozulib \
  && git clone https://github.com/herumi/msoffice \
  && cd msoffice \
  && make -j RELEASE=1 \
  && mv ./bin/msoffice-crypt.exe /usr/local/bin/msoffice-crypt \
  && cd ../.. \
  && rm -rf build

COPY . /app

RUN mkdir -p /home/appuser && \
  useradd appuser -u 1001 --user-group --home /home/appuser && \
  chown -R appuser:appuser /app && \
  chown -R appuser:appuser /home/appuser

USER 1001

RUN RAILS_ENV=production rails assets:precompile
