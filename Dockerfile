# Author: noraj
# Author website: https://rawsec.ml

FROM debian:stretch-20180831

RUN apt update && apt install -y ruby2.3
# install dependencies
RUN gem install cinch pwned

# drop privileges
RUN groupadd -g 1337 appuser && \
    useradd -r -u 1337 -g appuser appuser
USER appuser

ENV ENV_IP $ENV_IP

COPY ./irc_cinch.rb /usr/src/app/irc_cinch.rb
COPY ./10k_most_common.txt /usr/src/app/10k_most_common.txt
COPY ./flag.txt /usr/src/app/flag.txt

WORKDIR /usr/src/app

CMD ruby ./irc_cinch.rb ${ENV_IP}
