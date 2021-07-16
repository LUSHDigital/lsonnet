# lsonnet

## What is it?

lsonnet are the templates that Lush DevOps used to generate kubernetes manifests
customised with user defined and pipeline based configuration files. This tool only
handles the generation of Kubernetes manifests and is designed to slot into a
pipeline or whatever process is required for deploying to Kubernetes

## Why?

The manifests are defined with a superset of JSON called
[jsonnet](https://jsonnet.org). The reason this is used is because:

- Loops and conditionals exist for useful logic functions
- Can pass in external variables or JSON objects as parameters
- Can create functions to keep code more dry
- Has a golang library
- Has a unit testing framework
- jsonnet isn't as complex as a full programming and that's good as that it's more
  domain specific.

## Testing

We use a framework called [jsonnetunit](https://github.com/yugui/jsonnetunit) to
unit test each template. These live in the `./tests` directory. We have a
directory per template with a test suite per jsonnet file. There is also a
fixtures file that is expected to accompany this jsonnet file. This is the same
name as the jsonnet file but with a yaml extension.

To run the test framework, run `tusk test`.

## Repository Structure

### `config/`

This is where the files live that take care of creating the variables to be
passed to the templates.

##### `default.libsonnet`

In this file are the default variables, that may be replaced by the variables
passed in by a `values.json` file or by variables on the command-line.

##### `config.libsonnet`

This file is mainly responsible for importing the values file and CLI
variables, patching them onto the default variables, and creating a labels
object. *This file is important, as it is imported by every template file to
populate the keys*.

### `tests/`

This directory holds the test suites for jsonnetunit to use. Each directory
represenets a template. Each directory contains a number of different suites to
account for diffferent scenarios. Each suite consists of two files, with the
same filename with different extensions, one with `.jsonnet` and one with
`.yaml`. The jsonnet file holds the assertions and the yaml file holds the
fixtures for that suite.

### `templates/`

This folder houses all of the JSONNET templates along with the file that brings
them all together, `main.jsonnet`. To create a new template, create the JSONNET
template (you can look at others for best practice on importing the config),
then make sure to import it into `main.jsonnet`. `main.jsonnet` will then
render these templates into a single kubernetes object of a kind list that
contains all necessary templates to apply. It looks like this:

```bash { apiVersion: 'v1', kind: 'List', items: items, } ```

It would be a good idea to have a look at the other templates to see how
implementation has been generally done before building out your own :)

## Known challenges

* `Concatenation of data structures ([] + [], {} + {})`

If you want to conditionally have items in a data structure, you need to use
the
+ operator, like so: ``` local arr1 = ["foo", "bar", "baz"] local arr2 =
  [1,2,3] local arr3 = arr1 + arr2 arr3 == ["foo", "bar", "baz", 1, 2, 3] ```

In an object, the principle still applies: ```jsonnet { foo: { baz: 1 } + {
bar: 2 } }

---- renders ----

{ "foo": { "baz": 1, "bar": 2 } }

```

* `if / else statements`

These can be quite straightforward at first. It can work like so: ```jsonnet if
some_boolean_expression then { thisobject: "getsReturned" } else { thisone:
"does" } ```

You can do some other stuff too, like conditional adding to an object using the
+ operator:

```jsonnet { anObject: "with stuff", someMoreStuff: ["hello", "blah"] } + if
some_boolean_expression then { thisobject: "getsReturned" } else { thisone:
"does" } ```

* For loops

For loops are also a bit weird. The syntax is written after where you want to
loop, and _I think_ are always contained in arrays. So:

```jsonnet [{ element: element * 10 } for element in [1,2,3]]

---- renders ----

[ { "element": 10 }, { "element": 20 }, { "element": 30 } ]

```

## Go Commands

The source in this repository builds a binary to help orchestrate and manage the
jsonnet templates.

### lsonnet generate

`lsonnet` generate renders a Kuernetes manifest, using passed in variables of
appConfig and pipelineConfig to generate the manifest. Pipeline Config takes
precedent. These are passed in as file paths or as strings.

### lsonnet test

The test commands iterates through the test directory and renders all of the
jsonnet files it finds in the subdirectories, using the yaml files with the
associated jsonnet file of the same name. If you pass in `--debug`, you can see
the rendered test json object. You can also use `--unit` to test just a single
test jsonnet file.

### lsonnet migrate

The migrate command takes a helm release name as a single positional argument. 
It will then apply those values to the lsonnet templates and generate the static
templates that can be applied. We can then pipe the output to `kubectl` to apply
it or compare it.

### lsonnet validate

`validate` will loop though each test case, render all the templates using the
test fixtures and pass those through
[kubeval](https://github.com/instrumenta/kubeval] so that we can make sure it's
a valid Kubernetes resource against the version we specify.

### lsonnet server

We can run a simple http server to "template as a service". We can fire off a
HTTP POST at `/template` with a body container `{ "appConfig": {},
"pipelineConfig": {}}` and get the full Kubernetes template in the response. You
can get the version of `lsonnet` used by hitting `/version` with a GET request.

## Todo

- Validate schema: Validate the input config coming in to make sure a value
  actually exists for that config item.
- Use Kubernetes version for Kubeval as a parameter with a sensible default
- Better file structure
- Move Kingpin as it's no longer supported
- More flexibility around the directories and files expected

# Special Thanks

This was once closed source but now opened up. We had to ditch the git history 
for this release so I'd like to thank the following contributors who made
this happen:

- [Dan Potepa](https://github.com/cuotos)
- [Stephen Geller](https://github.com/stephengeller)
- [Icelyn Jennings](https://github.com/icelynjennings)
