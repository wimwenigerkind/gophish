// Package testdb picks the database the tests run against. By default that is
// an in-memory SQLite database; GOPHISH_TEST_DB_NAME and GOPHISH_TEST_DB_PATH
// point the tests at a server database instead, with the same values as
// db_name and db_path in config.json.
package testdb

import (
	"context"
	"database/sql"
	"fmt"
	"os"

	"github.com/gophish/gophish/config"

	_ "github.com/go-sql-driver/mysql"
	_ "github.com/jackc/pgx/v5/stdlib"
)

type fataler interface {
	Fatalf(format string, args ...interface{})
}

// Config returns a config for the test database. A server database outlives
// the test, so all of its tables are dropped first to give every setup the
// same empty database an in-memory SQLite database would.
func Config(t fataler) *config.Config {
	name := os.Getenv("GOPHISH_TEST_DB_NAME")
	path := os.Getenv("GOPHISH_TEST_DB_PATH")
	if name == "" || name == "sqlite3" {
		return &config.Config{DBName: "sqlite3", DBPath: ":memory:"}
	}
	if err := reset(name, path); err != nil {
		t.Fatalf("error resetting test database: %v", err)
	}
	return &config.Config{DBName: name, DBPath: path}
}

func reset(name, path string) error {
	driver := name
	if name == "postgres" {
		driver = "pgx"
	}
	db, err := sql.Open(driver, path)
	if err != nil {
		return err
	}
	defer db.Close()
	switch name {
	case "mysql":
		return resetMySQL(db)
	case "postgres":
		_, err := db.Exec("DROP SCHEMA public CASCADE; CREATE SCHEMA public")
		return err
	default:
		return fmt.Errorf("unsupported test database %q", name)
	}
}

func resetMySQL(db *sql.DB) error {
	// A dedicated connection, because FOREIGN_KEY_CHECKS is per session.
	conn, err := db.Conn(context.Background())
	if err != nil {
		return err
	}
	defer conn.Close()
	ctx := context.Background()
	rows, err := conn.QueryContext(ctx, "SELECT table_name FROM information_schema.tables WHERE table_schema = DATABASE()")
	if err != nil {
		return err
	}
	var tables []string
	for rows.Next() {
		var table string
		if err := rows.Scan(&table); err != nil {
			rows.Close()
			return err
		}
		tables = append(tables, table)
	}
	rows.Close()
	if _, err := conn.ExecContext(ctx, "SET FOREIGN_KEY_CHECKS = 0"); err != nil {
		return err
	}
	for _, table := range tables {
		if _, err := conn.ExecContext(ctx, "DROP TABLE `"+table+"`"); err != nil {
			return err
		}
	}
	_, err = conn.ExecContext(ctx, "SET FOREIGN_KEY_CHECKS = 1")
	return err
}
