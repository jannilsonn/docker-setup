#!/bin/bash

main() {
  options
  echo "DONE (options)"
  echo "~~~~~~~~~~~~~~~"

  files
  echo "~~~~~~~~~~~~~~~"
  echo "DONE (files)"
  echo "~~~~~~~~~~~~~~~"
}

options() {
  echo "Project name:"; read project_name
  echo "~~~~~~~~~~~~~~~"
  echo "Ruby version:"; read ruby
  [ -z $ruby ] && { ruby="latest" }
  echo "~~~~~~~~~~~~~~~"
  echo "Rails version:"; read rails
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

main