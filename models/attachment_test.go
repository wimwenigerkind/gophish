package models

import (
	"archive/zip"
	"bufio"
	"bytes"
	"encoding/base64"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/check.v1"
)

func (s *ModelsSuite) TestAttachment(c *check.C) {
	ptx := PhishingTemplateContext{
		BaseRecipient: BaseRecipient{
			FirstName: "Foo",
			LastName:  "Bar",
			Email:     "foo@bar.com",
			Position:  "Space Janitor",
		},
		BaseURL:     "http://testurl.com",
		URL:         "http://testurl.com/?rid=1234567",
		TrackingURL: "http://testurl.local/track?rid=1234567",
		Tracker:     "<img alt='' style='display: none' src='http://testurl.local/track?rid=1234567'/>",
		From:        "From Address",
		RId:         "1234567",
	}

	files, err := ioutil.ReadDir("testdata")
	if err != nil {
		log.Fatalf("Failed to open attachment folder 'testdata': %v\n", err)
	}
	for _, ff := range files {
		if !ff.IsDir() && !strings.Contains(ff.Name(), "templated") {
			fname := ff.Name()
			fmt.Printf("Checking attachment file -> %s\n", fname)
			data := readFile("testdata/" + fname)
			if filepath.Ext(fname) == ".b64" {
				fname = fname[:len(fname)-4]
			}
			a := Attachment{
				Content: data,
				Name:    fname,
			}
			t, err := a.ApplyTemplate(ptx)
			c.Assert(err, check.Equals, nil)
			c.Assert(a.vanillaFile, check.Equals, strings.Contains(fname, "without-vars"))
			c.Assert(a.vanillaFile, check.Not(check.Equals), strings.Contains(fname, "with-vars"))

			// Verfify template was applied as expected
			tt, err := ioutil.ReadAll(t)
			if err != nil {
				log.Fatalf("Failed to parse templated file '%s': %v\n", fname, err)
			}
			expectedOutput := readFile("testdata/" + strings.TrimSuffix(ff.Name(), filepath.Ext(ff.Name())) + ".templated" + filepath.Ext(ff.Name())) // e.g text-file-with-vars.templated.txt
			expected, err := base64.StdEncoding.DecodeString(expectedOutput)
			c.Assert(err, check.Equals, nil)
			// The compressed bytes of a rewritten Office archive depend on the
			// deflate implementation of the Go release, so archives are
			// compared by their entries instead.
			if expectedEntries, ok := zipEntries(expected); ok {
				actualEntries, ok := zipEntries(tt)
				c.Assert(ok, check.Equals, true)
				c.Assert(actualEntries, check.DeepEquals, expectedEntries)
			} else {
				c.Assert(base64.StdEncoding.EncodeToString(tt), check.Equals, expectedOutput)
			}
		}
	}
}

type zipEntry struct {
	Name    string
	Content string
}

// zipEntries returns the entries of a zip archive in order, or false if data
// is not a zip archive.
func zipEntries(data []byte) ([]zipEntry, bool) {
	r, err := zip.NewReader(bytes.NewReader(data), int64(len(data)))
	if err != nil {
		return nil, false
	}
	entries := []zipEntry{}
	for _, f := range r.File {
		rc, err := f.Open()
		if err != nil {
			return nil, false
		}
		content, err := ioutil.ReadAll(rc)
		rc.Close()
		if err != nil {
			return nil, false
		}
		entries = append(entries, zipEntry{Name: f.Name, Content: string(content)})
	}
	return entries, true
}

func readFile(fname string) string {
	f, err := os.Open(fname)
	if err != nil {
		log.Fatalf("Failed to open file '%s': %v\n", fname, err)
	}
	reader := bufio.NewReader(f)
	content, err := ioutil.ReadAll(reader)
	if err != nil {
		log.Fatalf("Failed to read file '%s': %v\n", fname, err)
	}
	data := ""
	if filepath.Ext(fname) == ".b64" {
		data = string(content)
	} else {
		data = base64.StdEncoding.EncodeToString(content)
	}
	return data
}
