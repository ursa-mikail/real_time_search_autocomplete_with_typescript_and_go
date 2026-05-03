package main

import (
	"log"
	"net/http"
	"os"

	"github.com/searchpulse/backend/internal/db"
	"github.com/searchpulse/backend/internal/handlers"
)

func main() {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		dsn = "postgres://searchpulse:searchpulse@localhost:5432/searchpulse?sslmode=disable"
	}

	database, err := db.Connect(dsn)
	if err != nil {
		log.Fatalf("db connect: %v", err)
	}
	defer database.Close()
	log.Println("✅ connected to postgres")

	h := handlers.New(database)

	mux := http.NewServeMux()
	mux.HandleFunc("GET /api/health",  h.Health)
	mux.HandleFunc("GET /api/suggest", h.Suggest)
	mux.HandleFunc("GET /api/search",  h.Search)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Printf("🚀 listening on :%s", port)
	if err := http.ListenAndServe(":"+port, cors(mux)); err != nil {
		log.Fatalf("server: %v", err)
	}
}

func cors(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}
