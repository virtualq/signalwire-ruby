FROM ruby:4.0.10@sha256:84e854507d7f2ffc9061e32d47c16d7413bcb1fa55ec29c1927f9e4d62fa6cf3

COPY . /app
WORKDIR /app

RUN gem install bundler --version 2.6.7 --no-document && bundle _2.6.7_ install
CMD ["bundle", "_2.6.7_", "exec", "rspec"]
