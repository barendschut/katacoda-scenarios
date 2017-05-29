FROM node:7.10.0-alpine
RUN mkdir /src/
COPY package.json /src/
WORKDIR /src/
RUN npm install --production
COPY src/ /src/
EXPOSE 3000
ENV NODE_ENV production
ENTRYPOINT ["node", "server.js"]