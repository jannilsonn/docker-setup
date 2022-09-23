#!/bin/bash

main() {
  options
  echo "DONE (options)"
  echo "~~~~~~~~~~~~~~~"

  files
  echo "~~~~~~~~~~~~~~~"
  echo "DONE (files)"
  echo "~~~~~~~~~~~~~~~"

  if [ $api = "S" ] || [ $api = "y" ]; then
    docker-compose run --no-deps --rm web rails new . --api --force --database=postgresql
  else
    docker-compose run --no-deps --rm web rails new . --force --database=postgresql
  fi
  echo "~~~~~~~~~~~~~~~"
  echo "DONE (rails new)"
  echo "~~~~~~~~~~~~~~~"

  docker-compose build --no-cache
  echo "~~~~~~~~~~~~~~~"
  echo "DONE (build)"
  echo "~~~~~~~~~~~~~~~"

  database
  echo "~~~~~~~~~~~~~~~"
  echo "DONE (config db)"
  echo "~~~~~~~~~~~~~~~"

  docker-compose run --rm web rake db:create
  echo "~~~~~~~~~~~~~~~"
  echo "DONE (db:create)"
  echo "~~~~~~~~~~~~~~~"

  echo "run 'docker-compose up'"
}

options() {
  echo "Project name:"; read project_name
  echo "~~~~~~~~~~~~~~~"
  echo "Ruby version:"; read ruby
  [ -z $ruby ] && { ruby="latest" }
  echo "~~~~~~~~~~~~~~~"
  echo "Rails version:"; read rails
  echo "~~~~~~~~~~~~~~~"
  echo "Just Rails API? Y/N"; read api
  if [ -z $rails ]; then
    gem_rails="gem 'rails'"
  else
    gem_rails="gem 'rails', '~> $rails'"
  fi
}

files() {
  dockerfile
  docker_compose
  gemfile
  touch Gemfile.lock
  entrypoint
}

dockerfile() {
  echo 'FROM ruby:'$ruby'

ENV INSTALL_PATH /opt/app

RUN curl -sL https://deb.nodesource.com/setup_lts.x | bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update -qq
RUN apt-get install -y --no-install-recommends nodejs postgresql-client \
      locales yarn

WORKDIR $INSTALL_PATH

COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
RUN gem install bundler
RUN bundle install

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

COPY . $INSTALL_PATH

CMD ["rails", "server", "-b", "0.0.0.0"]' >> Dockerfile
}

docker_compose() {
  echo 'version: "3.9"
services:
  db:
    image: postgres:12-alpine
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
    volumes:
      - data:/var/lib/postgresql/data
  web:
    build: .
    command: bash -c "rm -f tmp/pids/server.pid && bundle exec rails s -b '0.0.0.0'"
    container_name: '$project_name'
    ports:
      - 3000:3000
    volumes:
      - .:/opt/app
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_HOST=db
    depends_on:
      - db
volumes:
  data:' >> docker-compose.yml
}

gemfile() {
  echo "source 'https://rubygems.org'
$gem_rails" >> Gemfile
}

entrypoint() {
  echo '#!/bin/bash
set -e

rm -f /$project_name/tmp/pids/server.pid

exec "$@"' >> entrypoint.sh
}

database() {
  path_database="${PWD}/config/database.yml"

  rm -rf $path_database

  echo 'default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: <%= ENV.fetch("POSTGRES_USER") %>
  password: <%= ENV.fetch("POSTGRES_PASSWORD") %>
  host: <%= ENV.fetch("POSTGRES_HOST") %>

development:
  <<: *default
  database: app_development

test:
  <<: *default
  database: app_test

production:
  <<: *default
  database: app_production
  username: app
  password: <%= ENV["APP_DATABASE_PASSWORD"] %>' >> $path_database
}

main