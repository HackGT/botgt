FROM node:8-alpine
MAINTAINER Ehsan Asdar <easdar@gatech.edu>

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# Bundle app source
COPY . /usr/src/app
RUN npm install
RUN apk add tzdata
ENV TZ="/usr/share/zoneinfo/America/New_York"

CMD ["npm", "start"]
