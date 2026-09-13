FROM ruby:4.0.6

COPY . /app
WORKDIR /app

RUN gem install bundler --version 2.6.7 --no-document && bundle _2.6.7_ install
CMD ["bundle", "_2.6.7_", "exec", "rspec"]
