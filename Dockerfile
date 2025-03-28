# Build
FROM elixir:1.18-alpine AS builder

ARG MIX_ENV
ARG GUARDIAN_SECRET_KEY
ARG DATABASE_URL
ARG DB_SCHEMA

RUN mix local.hex --force && mix local.rebar --force

RUN apk add --no-cache build-base openssl ncurses-libs postgresql-dev postgresql-client libstdc++ ca-certificates curl

RUN curl -s -o /etc/ssl/certs/prod-ca-2021.crt https://supabase-downloads.s3-ap-southeast-1.amazonaws.com/prod/ssl/prod-ca-2021.crt && \
    chmod 644 /etc/ssl/certs/prod-ca-2021.crt && \
    update-ca-certificates

WORKDIR /app

COPY mix.exs mix.lock ./
COPY config config

RUN mix deps.get --only prod && mix deps.compile

COPY lib lib
COPY priv priv

RUN mix compile
RUN mix assets.deploy
RUN mix release

# Deploy
FROM alpine:3.19 AS app

ARG MIX_ENV
ARG GUARDIAN_SECRET_KEY
ARG DATABASE_URL
ARG DB_SCHEMA

RUN apk add --no-cache libstdc++ ncurses-libs openssl bash
RUN adduser -D app
USER app

WORKDIR /app
COPY --from=builder --chown=app:app /app/_build/prod/rel/vyre ./

ENTRYPOINT ["/app/bin/vyre"]
CMD ["start"]

EXPOSE 4000
