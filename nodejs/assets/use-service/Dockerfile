FROM node:7.10.0-alpine
RUN mkdir /src/
COPY package.json /src/
WORKDIR /src/
RUN npm install --production
COPY server.js /src/
EXPOSE <CONTAINER PORT>      
# ^--- FILL IN THIS LINE
ENV NODE_ENV production
ENTRYPOINT ["node", "server.js"]