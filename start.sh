#!/usr/bin/env bash

docker run -d -p 9411:9411 openzipkin/zipkin
source .env && iex -S mix phx.server