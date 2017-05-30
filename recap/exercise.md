Run your own web server!

Requirements:
- dockerized `nginx:1.12.0-alpine`
- `curl host01:8080` should output „Hello Docker!“

Hints:

- NGINX serves **index.html** from **/usr/share/nginx/html/**
- Dockerfile: **FROM** and **COPY** is enough
- Build your image: `docker build -t <image-name> .`
- NGINX listens on **port 80** by default
