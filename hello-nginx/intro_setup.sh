#!/bin/sh

touch /INTRO_SETUP_MADE_THIS
docker build -t abc .
docker pull traefik