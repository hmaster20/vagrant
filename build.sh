#!/bin/bash

set -e

# Получаем версию из аргумента или устанавливаем dev по умолчанию
VERSION=${1:-dev}

# Директория для бинарников
OUTPUT_DIR="output"
mkdir -p "$OUTPUT_DIR"

# Убедимся, что Go установлен
if ! command -v go &> /dev/null
then
    echo "Go не установлен. Установите Go."
    exit 1
fi

# Синхронизация vendor
echo "Синхронизация vendor..."
go mod tidy
go mod vendor

# Сборка Linux версии
echo "Сборка для Linux..."
GOOS=linux GOARCH=amd64 go build -mod=mod -o "$OUTPUT_DIR/vagrant_linux_amd64" ./cmd/vagrant

# Сборка Windows версии
echo "Сборка для Windows..."
GOOS=windows GOARCH=amd64 go build -mod=mod -o "$OUTPUT_DIR/vagrant_windows_amd64.exe" ./cmd/vagrant

# Переименовываем с добавлением версии
mv "$OUTPUT_DIR/vagrant_linux_amd64" "$OUTPUT_DIR/vagrant_linux_amd64-$VERSION"
mv "$OUTPUT_DIR/vagrant_windows_amd64.exe" "$OUTPUT_DIR/vagrant_windows_amd64-$VERSION.exe"

# Установка зависимостей через bundle
echo "Установка Ruby-зависимостей..."
bundle config set --local path 'vendor/bundle'
bundle install --retry 3 --jobs 3

# Создание .gem файла
echo "Создание .gem пакета..."
bundle exec rake package

# Копируем гем в output
GEM_NAME=$(ls pkg/*.gem | head -n 1)
cp "$GEM_NAME" "$OUTPUT_DIR/${GEM_NAME##*/}-${VERSION}.gem"

echo "Сборка завершена. Бинарные файлы сохранены в $OUTPUT_DIR"