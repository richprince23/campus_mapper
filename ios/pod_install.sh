#!/bin/bash

command="pod install"

until $command; do
  echo "Command failed. Retrying..."
  sleep 1 # Optional: add a delay between retries
done

echo "Command succeeded."