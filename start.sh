#!/usr/bin/env bash

# docker run -d -p 9411:9411 openzipkin/zipkin
# source .env && docker run -p 9411:9411 honeycombio/honeycomb-opentracing-proxy -k $HONEYCOMB_KEY -d traces
source .env &&
iex -S mix phx.server