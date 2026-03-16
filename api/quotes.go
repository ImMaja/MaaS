package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
)

type Quote struct {
	Text   string `json:"quote"`
	Author string `json:"author"`
}

func LoadQuotesFromJSONL(filePath string) ([]Quote, error) {
	var quotes []Quote
	file, err := os.Open(filePath)
	if err != nil {
		fmt.Fprintln(os.Stderr, "Cannot open file "+filePath)
		return nil, err
	}

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		var q = Quote{}
		json.Unmarshal([]byte(line), &q)
		quotes = append(quotes, q)
	}

	defer file.Close()
	return quotes, nil
}
