package main

import (
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	kingpin "gopkg.in/alecthomas/kingpin.v2"
	"k8s.io/client-go/kubernetes"
	_ "k8s.io/client-go/plugin/pkg/client/auth/gcp"
	restclient "k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/helm/pkg/chartutil"
	"k8s.io/helm/pkg/helm/portforwarder"
	"k8s.io/helm/pkg/kube"

	log "github.com/apex/log"
	"github.com/apex/log/handlers/cli"
	"github.com/ghodss/yaml"
	jsonnet "github.com/google/go-jsonnet"
	"github.com/instrumenta/kubeval/kubeval"
	color "github.com/logrusorgru/aurora"
	"k8s.io/helm/pkg/helm"
)

var (
	app                    = kingpin.New("lsonnet", "A command-line utility for the Lush kube templates.")
	debug                  = app.Flag("debug", "Enable debug mode.").Bool()
	test                   = app.Command("test", "Test the lsonnet templates")
	testFile               = test.Flag("unit", "The specific test to run").String()
	migrate                = app.Command("migrate", "Generate templaes to migrate an app to Lsonnet")
	migrateRelease         = migrate.Arg("release", "The release to get values from").Required().String()
	generate               = app.Command("generate", "Generate static manifests")
	generateAppConfig      = generate.Flag("appconfig", "The app config file path supplied by yaml files from the app source").Required().String()
	generatePipelineConfig = generate.Flag("pipelineconfig", "The pipeline config file path").Required().String()
	render                 = app.Command("render", "Render jsonnet. Useful for debugging tests.")
	renderJsonnetTemplate  = render.Flag("template", "The jsonnet template to render").Required().String()
	renderAppConfig        = render.Flag("appconfig", "The app config file path supplied by yaml files from the app source").Required().String()
	validate               = app.Command("validate", "Validate test templates against kubeval")
	validateFile           = validate.Flag("unit", "The specific test to run").String()
	server                 = app.Command("server", "Run lsonnet as a server")

	version string
)

const (
	defaultVersionString = "unset"
	versionEnvVar = "VERSION"
)

func main() {
	// Setup our logger
	log.SetHandler(cli.Default)

	switch kingpin.MustParse(app.Parse(os.Args[1:])) {
	// Test lsonnet
	case test.FullCommand():
		setLogLevel(*debug)
		testFunc(*testFile, *debug)

	// Generate manifests for migrating an app
	case migrate.FullCommand():
		if *migrateRelease == "" {
			log.Fatalf("Please enter the release name")
		}
		setLogLevel(*debug)
		migrateFunc(*migrateRelease)

	// Use appconfig and pipelineconfig objects passed in via commandline to
	// generate templates
	case generate.FullCommand():
		generateFunc(*generateAppConfig, *generatePipelineConfig)

	// Use appconfig objects passed in via commandline to
	// render jsonnet templates
	case render.FullCommand():
		renderFunc(*renderJsonnetTemplate, *renderAppConfig)

	// Validate test files against kubeval
	case validate.FullCommand():
		setLogLevel(*debug)
		validateFunc(*validateFile)

	// Server runs lsonnet as a server
	case server.FullCommand():
		setLogLevel(*debug)
		serverFunc()
	}

}

func testFunc(testFile string, debug bool) {
	var testDirs []string
	var traceConfig string
	var traceValue bool

	if debug {
		traceValue = true
	} else {
		traceValue = false
	}

	traceConfig = fmt.Sprintf("{\"trace\": %v}", traceValue)

	testDirectory := "./tests/"
	exitCode := 0

	if testFile == "" {
		// Walk the directory and grab each test file
		err := filepath.Walk(testDirectory, func(path string, info os.FileInfo, err error) error {
			if filepath.Ext(path) == ".jsonnet" {
				testDirs = append(testDirs, path)
			}
			return nil
		})
		if err != nil {
			panic(err)
		}
	} else {
		testDirs = append(testDirs, testFile)
	}

	// Go through each of the test test files and convert them to an array of map interfaces
	for _, file := range testDirs {
		log.Infof("file being processed is: %s", file)

		// Read fixtures
		appConfig, err := fileToJSON(strings.Replace(file, ".jsonnet", ".yaml", -1))
		if err != nil {
			log.Fatalf("error converting appConfig file to yaml: %s", err)
		}

		// Throw away the template and only care about the error
		if output, err := renderJsonnet(string(appConfig), traceConfig, file); err != nil {
			if traceValue {
				log.Debug(output)
			}
			log.Infof(color.Sprintf(color.Red("test for %s failed with %s"), file, err))
			exitCode = 1
		} else {
			if traceValue {
				log.Debug(output)
			}
			log.Infof(color.Sprintf(color.Green("tests passed for %s!"), file))
		}
	}

	os.Exit(exitCode)
}

func validateFunc(testFile string) {
	var testDirs []string
	var traceValue bool

	testDirectory := "./tests/"
	exitCode := 0

	if testFile == "" {
		// Walk the directory and grab each test file
		err := filepath.Walk(testDirectory, func(path string, info os.FileInfo, err error) error {
			if filepath.Ext(path) == ".yaml" {
				testDirs = append(testDirs, path)
			}
			return nil
		})
		if err != nil {
			panic(err)
		}
	} else {
		testDirs = append(testDirs, testFile)
	}

	// Go through each of the test test files and convert them to an array of map interfaces
	for _, file := range testDirs {
		log.Infof("file being processed is: %s", file)

		// Read fixtures
		appConfig, err := fileToJSON(file)
		if err != nil {
			log.Fatalf("error converting appConfig file to yaml: %s", err)
		}

		// Throw away the template and only care about the error
		if output, err := renderJsonnet(string(appConfig), "{}", "templates/main.jsonnet"); err != nil {
			if traceValue {
				log.Debug(output)
			}
			log.Infof(color.Sprintf(color.Red("Render for %s failed with %s"), file, err))
			exitCode = 1
		} else {
			// Need to control the failures fo an an individual test here
			var failed int

			log.Debugf("Template is %v", output)
			config := &kubeval.Config{
				OpenShift:         false,
				Strict:            true,
				ExitOnError:       false,
				FileName:          file,
				DefaultNamespace:  "default",
				KubernetesVersion: "1.16.0",
			}

			results, err := kubeval.Validate([]byte(output), config)
			log.Debugf("Results are %v", results)
			for _, resource := range results {
				if len(resource.Errors) > 0 {
					exitCode = 1
					failed = 1
					log.Errorf("error found for file %s in %s(%s): %v", file, resource.ResourceName, resource.Kind, resource.Errors)
				}
			}
			if err != nil {
				exitCode = 1
				failed = 1
				log.Errorf("error validating file %s: %v", file, err)
			}

			// kubeval doesn't throw errors if strict is turned on but has fields
			// that aren't in the spec despite errors being added to the result
			if failed == 0 {
				log.Infof(color.Sprintf(color.Green("validation passed for %s!"), file))
			}
		}
	}

	os.Exit(exitCode)
}

func migrateFunc(release string) {
	kubeClient, kubeConfig, err := getKubeClient()
	if err != nil {
		log.Fatal(err.Error())
	}

	helmClient, portForward, err := connectToTiller(kubeClient, kubeConfig)
	if err != nil {
		log.Fatal(err.Error())
	}
	defer portForward.Close()

	// Get the values of the release we passed in so we can pass them to jsonnet
	values, err := getValuesJSON(helmClient, release)
	if err != nil {
		log.Fatal(err.Error())
	}

	template, err := renderJsonnet(string(values), "{}", "templates/main.jsonnet")
	if err != nil {
		log.Fatal(err.Error())
	}

	// Don't log this so we only present the templates
	// This will allow us to pipe the output into kubectl
	fmt.Printf("\n%s", string(template))
}

func generateFunc(appconfig, pipelineconfig string) {
	yamlAppConfig, err := fileToJSON(appconfig)
	if err != nil {
		log.Fatal(err.Error())
	}

	yamlPipelineConfig, err := fileToJSON(pipelineconfig)
	if err != nil {
		log.Fatal(err.Error())
	}

	template, err := renderJsonnet(string(yamlAppConfig), string(yamlPipelineConfig), "./templates/main.jsonnet")
	if err != nil {
		log.Fatal(err.Error())
	}

	fmt.Printf("\n%s", string(template))
}

func renderFunc(jsonnetTemplate, appconfig string) {
	yamlAppConfig, err := fileToJSON(appconfig)
	if err != nil {
		log.Fatal(err.Error())
	}

	template, err := renderJsonnet(string(yamlAppConfig), "{}", jsonnetTemplate)
	if err != nil {
		log.Fatal(err.Error())
	}

	fmt.Printf("\n%s", string(template))
}

type ServerRequestBody struct {
	AppConfig      map[string]interface{} `json:"appConfig"`
	PipelineConfig map[string]interface{} `json:"pipelineConfig"`
}

func (body *ServerRequestBody) IsValid() (bool, string) {
	if body.AppConfig == nil || body.PipelineConfig == nil {
		return false, "appConfig and pipelineConfig cannot be nil"
	}
	return true, ""
}

func serverFunc() {

	templateHandler := func(w http.ResponseWriter, req *http.Request) {

		object := &ServerRequestBody{}

		// Read the body, we dont need to stream as this isn't big data (GB's)
		body, err := ioutil.ReadAll(req.Body)
		if err != nil {
			log.Errorf("cannot read request body: %v", err)
			return
		}
		defer req.Body.Close()

		// unmarshal the body into a ServerRequstBody object which will enforce it contains the minimum fields
		err = json.Unmarshal(body, object)
		if err != nil {
			log.Errorf("cannot unmarshal request body: %v", err)
			http.Error(w, fmt.Sprintf("cannot unmarshal request body: %v", err), http.StatusBadRequest)
			return
		}

		if valid, msg := object.IsValid(); !valid {
			http.Error(w, fmt.Sprintf("invalid input: %v", msg), http.StatusBadRequest)
			return
		}

		log.Debugf("Body: %v", object)

		appConfig, err := json.Marshal(object.AppConfig)
		if err != nil {
			log.Errorf("Can't marshal appConfig: %v", err)
		}

		pipelineConfig, err := json.Marshal(object.PipelineConfig)
		if err != nil {
			log.Errorf("Can't marshal pipelineConfig: %v", err)
		}

		log.Debugf("appConfig is %s", appConfig)
		log.Debugf("pipelineConfig is %s", pipelineConfig)

		template, err := renderJsonnet(string(appConfig), string(pipelineConfig), "templates/main.jsonnet")
		if err != nil {
			log.Errorf("Error rendering template: %v", err)
		}
		io.WriteString(w, template)
	}

	versionHandler := getVersionHandler(version)

	http.HandleFunc("/template", templateHandler)
	http.HandleFunc("/version", versionHandler)
	log.Info("Starting server")
	http.ListenAndServe(":8080", nil)
}

func getVersionHandler(version string) http.HandlerFunc {
	return func(w http.ResponseWriter, req *http.Request) {
		// If version wasn't passed into the build, try and get it from the ENV
		if version == "" {
			if v, ok := os.LookupEnv(versionEnvVar); ok && v != "" {
				version = v
			} else {
				version = defaultVersionString
			}
		}

		io.WriteString(w, version)
	}
}

// Take a file path and generate a map interface interface out of the yaml
func fileToJSON(file string) ([]byte, error) {
	appConfigFile, err := ioutil.ReadFile(file)
	if err != nil {
		return nil, err
	}

	json, err := yaml.YAMLToJSON(appConfigFile)
	if err != nil {
		return nil, err
	}

	return json, nil
}

func renderJsonnet(appConfig, pipelineConfig, file string) (string, error) {

	renderer := jsonnet.MakeVM()
	importer := jsonnet.FileImporter{}

	renderer.ExtCode("appConfig", appConfig)
	renderer.ExtCode("pipelineConfig", pipelineConfig)

	template, _, err := importer.Import(".", file)
	if err != nil {
		return "", fmt.Errorf("Something went wrong templating jsonnet: %s", err)
	}

	output, err := renderer.EvaluateSnippet("file", template.String())

	return output, err
}

func setLogLevel(level bool) {
	if level {
		log.SetLevel(log.DebugLevel)
	} else {
		log.SetLevel(log.InfoLevel)
	}
}

func getKubeClient() (*kubernetes.Clientset, *restclient.Config, error) {
	// This will grab your current kube config. This is only primed for macs
	// and works against your current context when running the command
	homeDir := os.Getenv("HOME")
	kubeConfig := filepath.Join(homeDir, ".kube", "config")

	log.Debugf("Get kube config from homedir")
	config, err := clientcmd.BuildConfigFromFlags("", kubeConfig)
	if err != nil {
		return nil, nil, fmt.Errorf("Can't get kubeconfig from the homedir: %s", err)
	}

	log.Debugf("Build clientset from kubeconfig")
	client, err := kubernetes.NewForConfig(config)
	if err != nil {
		return nil, nil, fmt.Errorf("Can't build the clientset from the kubeconfig: %s", err)
	}

	return client, config, nil
}

func connectToTiller(kubeClient *kubernetes.Clientset, kubeConfig *restclient.Config) (*helm.Client, *kube.Tunnel, error) {
	// Helm works by creating a kube tunnel to the tiller
	// The kube functions for creating a port forward are pretty low level so we
	// use an abstraction in a helm package to do it for us
	portForward, err := portforwarder.New("kube-system", kubeClient, kubeConfig)
	if err != nil {
		return nil, nil, fmt.Errorf("Can't build the tunnel with helm: %s", err)
	}

	clientOptions := []helm.Option{helm.Host(fmt.Sprintf("127.0.0.1:%d", portForward.Local))}
	client := helm.NewClient(clientOptions...)

	err = client.PingTiller()
	if err != nil {
		return nil, nil, fmt.Errorf("Couldn't connect to the tiller: %s", err)
	}

	log.Debugf("Connected to the tiller")

	// Pass portForward back out so we can defer the close
	return client, portForward, nil
}

func getValuesJSON(client *helm.Client, release string) ([]byte, error) {

	releaseContentOptions := []helm.ContentOption{}
	rel, err := client.ReleaseContent(release, releaseContentOptions...)
	if err != nil {
		return []byte{}, fmt.Errorf("Error with getting the release content for %s: %s", release, err)
	}

	// CoalesceValues grabs every value, including those that are computed
	// and those passed in
	values, err := chartutil.CoalesceValues(rel.Release.Chart, rel.Release.Config)
	if err != nil {
		return []byte{}, fmt.Errorf("Error with getting ALL values for %s: %s", release, err)
	}

	valuesJSON, err := json.MarshalIndent(values, " ", " ")
	if err != nil {
		return []byte{}, fmt.Errorf("Error with marshalling for %s: %s", release, err)
	}

	// Only prints with --debug flag due to log level
	log.Debugf("Values are %s:\n", string(valuesJSON))

	return valuesJSON, nil
}
