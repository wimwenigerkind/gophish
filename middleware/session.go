package middleware

import (
	"encoding/gob"
	"net/http"

	"github.com/gophish/gophish/models"
	"github.com/gorilla/securecookie"
	"github.com/gorilla/sessions"
)

// init registers the necessary models to be saved in the session later
func init() {
	gob.Register(&models.User{})
	gob.Register(&models.Flash{})
	Store.Options.HttpOnly = true
	// gorilla/sessions defaults the cookie to SameSite=None since v1.3, and
	// browsers such as Chrome drop a SameSite=None cookie that is not Secure,
	// which gophish never sets. The admin session is same-site, so Lax is enough.
	Store.Options.SameSite = http.SameSiteLaxMode
	// This sets the maxAge to 5 days for all cookies
	Store.MaxAge(86400 * 5)
}

// Store contains the session information for the request
var Store = sessions.NewCookieStore(
	[]byte(securecookie.GenerateRandomKey(64)), //Signing key
	[]byte(securecookie.GenerateRandomKey(32)))
