#!/bin/sh

sudo sysctl -w net.ipv4.ip_forward=1

docker-compose down
docker-compose up -d
