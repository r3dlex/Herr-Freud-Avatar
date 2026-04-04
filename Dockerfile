# Build stage
FROM elixir:1.14-alpine AS builder

RUN apk add --no-cache build-base git

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get && mix deps.compile

COPY lib/ ./lib/
COPY config/ ./config/
COPY priv/ ./priv/

RUN mix compile

RUN mix release

FROM alpine:3.18 AS releaser

RUN apk add --no-cache openssl ncurses-libs libcrypto3 libncursesw6
RUN apk add --no-cache python3 py3-pip

WORKDIR /app

COPY --from=builder /app/_build/release/herr_freud /app/herr_freud

ENV TERM=xterm

CMD ["/app/herr_freud/bin/herr_freud", "start"]