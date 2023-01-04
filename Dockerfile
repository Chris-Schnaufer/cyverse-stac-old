FROM ubuntu:22.04 as base

RUN apt update && \
    apt install git nodejs npm -y

RUN git clone https://github.com/radiantearth/stac-browser.git --single-branch && \
    cd stac-browser && \
     npm install

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

CMD [ "/entrypoint.sh" ]