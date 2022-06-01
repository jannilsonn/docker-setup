#!/bin/bash

main() {
  options
  echo "DONE (options)"
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

main