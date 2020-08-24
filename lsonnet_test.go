package main

import (
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	filet "github.com/Flaque/filet"
	"github.com/stretchr/testify/assert"
)

func TestFileToJSON(t *testing.T) {
	cases := []struct {
		yaml, json  string
		errors      bool
		errorString string
	}{
		{
			"---\nfoo: bar",
			"{\"foo\":\"bar\"}",
			false,
			"",
		},
		{
			"hi:oh\nhi:",
			"",
			true,
			"yaml: line 2: mapping values are not allowed in this context",
		},
	}

	for _, c := range cases {
		filePath := filet.TmpFile(t, "", c.yaml)
		defer filet.CleanUp(t)

		fileJSON, err := fileToJSON(filePath.Name())

		assert.Equal(t, string(fileJSON), c.json, "they should be equal")
		if c.errors {
			assert.EqualError(t, err, c.errorString)
		}
	}
}

func TestRenderJSONNET(t *testing.T) {
	cases := []struct {
		inputs      string
		template    string
		errors      bool
		errorString string
	}{
		{
			"{\"foo\": \"bar\"}",
			"{\n   \"foo\": \"bar\"\n}\n",
			false,
			"",
		},
		{
			"{}",
			"",
			true,
			"RUNTIME ERROR: Field does not exist: foo\n\tfile:4:11-21\tobject <anonymous>\n\tDuring manifestation\t\n",
		},
	}

	template := `
      local config = std.extVar("appConfig");
			{
			  foo: config.foo
			}
		`
	templateFile := filet.TmpFile(t, "", template)
	defer filet.CleanUp(t)

	for _, c := range cases {

		output, err := renderJsonnet(c.inputs, "{}", templateFile.Name())
		assert.Equal(t, output, c.template, "they should be equal")
		if c.errors {
			assert.EqualError(t, err, c.errorString)
		}
	}
}

func TestVersionHandler(t *testing.T) {
	tcs := []struct{
		Name string
		InputVersion string
		InputEnvVar string
		Expected string
	}{
		{
			"version var set",
			"v1.2.3",
			"",
			"v1.2.3",
		},
		{
			"no version provided and no env var",
			"",
			"",
			defaultVersionString,
		},
		{
			"no version number, but env var is set",
			"",
			"env-var-version",
			"env-var-version",
		},
		{
			"both version and env var are set, version should win",
			"baked-in version",
			"env var version",
			"baked-in version",
		},
	}

	for _, tc := range tcs {
		t.Run(tc.Name, func(t *testing.T) {
			os.Setenv(versionEnvVar, tc.InputEnvVar)
			defer os.Unsetenv(versionEnvVar)

			rr := httptest.NewRecorder()
			req, _ := http.NewRequest("GET", "/version", nil)

			h := getVersionHandler(tc.InputVersion)
			h(rr, req)

			b, _ := ioutil.ReadAll(rr.Body)
			assert.Equal(t, tc.Expected, string(b))
		})
	}
}