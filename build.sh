#!/bin/bash

set -e

# Получаем версию из аргумента или устанавливаем dev по умолчанию
VERSION=${1:-dev}

# Директория для бинарников
OUTPUT_DIR="../output"
mkdir -p "$OUTPUT_DIR"

# Переходим в директорию vagrant
cd vagrant || exit 1

# Устанавливаем bundler и зависимости
gem install bundler --no-document
bundle config set --local path 'vendor/bundle'
bundle install

# Обновляем версию в Gemfile если это не dev
if [[ "$VERSION" != "dev" ]]; then
  sed -i "s/\(gem 'vagrant', path: 'vendor\/vagrant'\)/# gem 'vagrant', path: 'vendor\/vagrant'/" ../Gemfile
  echo "gem 'vagrant', '=$VERSION'" >> ../Gemfile
fi

# Собираем гем
bundle exec rake package

# Копируем результат
GEM_NAME="vagrant-${VERSION}.gem"
cp pkg/*.gem "$OUTPUT_DIR/"

# Создаём standalone .exe (Windows)
gem install ocra --no-document
ocra --output "$OUTPUT_DIR/vagrant_windows_amd64.exe" bin/vagrant

# Создаём portable Linux версию
mkdir -p dist/linux
APP_NAME="vagrant_linux_amd64"
mkdir -p "$APP_NAME"
cp bin/vagrant "$APP_NAME/"
cp -r lib templates "$APP_NAME/"

tar -czf "$OUTPUT_DIR/$APP_NAME.tar.gz" -C "$APP_NAME" .

echo "Сборка завершена. Бинарные файлы сохранены в $OUTPUT_DIR"
