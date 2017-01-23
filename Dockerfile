FROM node:boron
MAINTAINER Ehsan Asdar <easdar@gatech.edu>

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# Bundle app source
COPY . /usr/src/app

CMD ["npm", "start"]
