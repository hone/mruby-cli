FROM hone/mruby-cli:15.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    add-apt-repository ppa:george-edison55/cmake-3.x && \
    apt-get update && \
    apt-get upgrade -y cmake

