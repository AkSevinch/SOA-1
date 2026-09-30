// Catalog Service — минимальный HTTP-сервис с health-check.
//
// Условие задания прямо запрещает бизнес-логику на этом этапе, поэтому сервис
// делает ровно одну вещь: отвечает 200 OK на /health. Этого достаточно, чтобы
// поднять его в Docker и выполнить требование «сервис отвечает 200 OK».
package main

import (
	"net/http"
	"time"
)

// Адрес прослушивания. Константа вместо переменной окружения: конфигурация
// на этом этапе не нужна.
const addr = ":8080"

func health(w http.ResponseWriter, _ *http.Request) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(`{"status":"ok"}`))
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", health)

	server := &http.Server{
		Addr:              addr,
		Handler:           mux,
		ReadHeaderTimeout: 5 * time.Second,
	}

	_ = server.ListenAndServe()
}
