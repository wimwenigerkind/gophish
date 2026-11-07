package models

import (
	"testing"

	"github.com/go-sql-driver/mysql"
)

func TestAllowZeroDates(t *testing.T) {
	cfg, err := mysql.ParseDSN("root:pw@tcp(127.0.0.1:3306)/gophish")
	if err != nil {
		t.Fatal(err)
	}
	allowZeroDates(cfg)
	if cfg.Params["sql_mode"] == "" {
		t.Fatal("expected allowZeroDates to set sql_mode")
	}

	cfg, err = mysql.ParseDSN("root:pw@tcp(127.0.0.1:3306)/gophish?sql_mode=%27ANSI%27")
	if err != nil {
		t.Fatal(err)
	}
	allowZeroDates(cfg)
	if got := cfg.Params["sql_mode"]; got != "'ANSI'" {
		t.Fatalf("expected the sql_mode from the DSN to win, got %q", got)
	}
}
