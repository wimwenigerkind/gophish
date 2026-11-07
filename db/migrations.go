// Package db embeds the SQL migrations of every supported database, so the
// gophish binary runs without the db directory next to it.
package db

import "embed"

// Migrations holds one db_<dialect>/migrations directory per dialect.
//
//go:embed db_*/migrations/*.sql
var Migrations embed.FS
