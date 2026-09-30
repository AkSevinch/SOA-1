# Сборка. Компилятор Go нужен только на этом этапе и в итоговый образ
# не попадает: в runtime-образе остаётся лишь бинарник на несколько мегабайт.
FROM golang:1.26-alpine AS builder

WORKDIR /src

COPY go.mod ./
COPY main.go ./

# CGO выключен, чтобы бинарник был статическим и не зависел от libc.
RUN CGO_ENABLED=0 go build -trimpath -o /out/catalog-service .

# Запуск. В образе только бинарник.
FROM alpine:3.22

COPY --from=builder /out/catalog-service /usr/local/bin/catalog-service

EXPOSE 8080

# Docker сам запрашивает /health каждые 10 секунд и помечает контейнер как
# healthy, если команда завершилась с кодом 0. Именно это видно в docker ps.
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:8080/health || exit 1

ENTRYPOINT ["/usr/local/bin/catalog-service"]
