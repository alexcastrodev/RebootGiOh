FROM ruby:4.0.5-slim

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libsqlite3-dev \
      libyaml-dev \
      pkg-config && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock* ./
RUN bundle install --without development test

COPY . .

EXPOSE 4567
CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:4567", "config.ru"]
