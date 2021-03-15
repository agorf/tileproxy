FROM ruby:2.6-alpine

RUN apk update && apk add \
      build-base

WORKDIR /usr/src/app/

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN bundle install

EXPOSE 9292

CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0"]
