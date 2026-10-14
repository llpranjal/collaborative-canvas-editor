# Build the web client.
FROM node:22-alpine AS web
WORKDIR /web
COPY web/package.json web/package-lock.json ./
RUN npm ci
COPY web/ ./
RUN npm run build

# Build the server (SQLite is compiled in via rusqlite's `bundled` feature).
FROM rust:1.84-slim AS server
WORKDIR /server
COPY server/ ./
RUN cargo build --release --locked

# One small image: the binary serves the API, WebSockets, and the static client.
FROM debian:bookworm-slim
RUN useradd --system --uid 10001 canvas && mkdir -p /data && chown canvas /data
COPY --from=server /server/target/release/collaborative-canvas-server /usr/local/bin/collaborative-canvas-server
COPY --from=web /web/dist /app/web
ENV PORT=8787 CANVAS_DB=/data/canvas.db CANVAS_STATIC=/app/web RUST_LOG=info
VOLUME /data
EXPOSE 8787
USER canvas
CMD ["collaborative-canvas-server"]
