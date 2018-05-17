#!/bin/sh
tag=build-$(date +%s)
docker build -t my-nginx:"$tag" .
docker run -d -p 8080:80 my-nginx:"$tag"