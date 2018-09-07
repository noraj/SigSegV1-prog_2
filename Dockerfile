# Author: noraj
# Author website: https://rawsec.ml

FROM ruby:2.5-stretch

ENV ENV_IP $ENV_IP

COPY ./irc_cinch.rb /usr/src/app/irc_cinch.rb
COPY ./10k_most_common.txt /usr/src/app/10k_most_common.txt

WORKDIR /usr/src/app

# install dependencies
RUN gem install cinch pwned

CMD ruby ./irc_cinch.rb ${ENV_IP}
