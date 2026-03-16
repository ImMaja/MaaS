package main

import (
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"os"
)

type App struct {
	Port   string
	Quotes []Quote
}

func (app *App) quoteHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "", http.StatusMethodNotAllowed)
		return
	}
	w.Header().Set("Content-Type", "application/json")

	n := len(app.Quotes)
	index := rand.Intn(n)
	quote := app.Quotes[index]

	json.NewEncoder(w).Encode(quote)
}

func main() {
	quotes, err := LoadQuotesFromJSONL("data/quotes.jsonl")
	if err != nil {
		return
	}
	if len(quotes) == 0 {
		fmt.Fprintln(os.Stderr, "Empty set or all quotes are malformed")
		return
	}

	app := &App{
		Port:   "127.0.0.1:8080",
		Quotes: quotes,
	}

	http.HandleFunc("/quote", app.quoteHandler)
	fmt.Println("Ready")
	http.ListenAndServe(app.Port, nil)
}
