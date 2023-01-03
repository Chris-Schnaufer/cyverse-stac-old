FROM ubuntu:22.04 as base

#ENV NODE_ENV=production

RUN apt update && \
    apt install git nodejs npm -y

RUN git clone https://github.com/radiantearth/stac-browser.git --single-branch && \
    cd stac-browser && \
     npm install
#    npm install --omit=dev && \
#    npm install @vue/cli
    # && \
    #npm install ronin-server ronin-mocks

#COPY server.js stac-browser/

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

#CMD [ "npm", "/stac-browser/server.js" ]
CMD [ "/entrypoint.sh" ]