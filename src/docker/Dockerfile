FROM ubuntu:latest

RUN apt-get update && apt-get clean && apt-get install -y \
    gnupg2 \
    x11vnc \
    xvfb \
    fluxbox \
    wmctrl \
    wget
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list \
    && apt-get update && apt-get -y install google-chrome-stable

RUN rm -rf /var/lib/apt/lists/*

RUN useradd apps \
    && mkdir -p /home/apps \
    && chown -v -R apps:apps /home/apps

COPY bootstrap.sh /
RUN chmod a+x /bootstrap.sh

CMD '/bootstrap.sh'
