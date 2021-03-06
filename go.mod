module lsonnet

go 1.14

require (
	github.com/DATA-DOG/go-sqlmock v1.4.1 // indirect
	github.com/Flaque/filet v0.0.0-20190209224823-fc4d33cfcf93
	github.com/Masterminds/goutils v1.1.0 // indirect
	github.com/Masterminds/semver v1.5.0 // indirect
	github.com/Masterminds/sprig v2.22.0+incompatible // indirect
	github.com/apex/log v1.3.0
	github.com/coreos/go-systemd v0.0.0-20190321100706-95778dfbb74e // indirect
	github.com/elazarl/goproxy v0.0.0-20180725130230-947c36da3153 // indirect
	github.com/ghodss/yaml v1.0.0
	github.com/go-openapi/jsonreference v0.19.3 // indirect
	github.com/go-openapi/spec v0.19.3 // indirect
	github.com/gogo/protobuf v1.3.1 // indirect
	github.com/google/go-jsonnet v0.16.0
	github.com/google/gofuzz v1.1.0 // indirect
	github.com/googleapis/gnostic v0.1.0 // indirect
	github.com/huandu/xstrings v1.3.1 // indirect
	github.com/instrumenta/kubeval v0.0.0-20200515185822-7721cbec724c
	github.com/jmoiron/sqlx v1.2.0 // indirect
	github.com/lib/pq v1.6.0 // indirect
	github.com/logrusorgru/aurora v0.0.0-20181002194514-a7b3b318ed4e
	github.com/mailru/easyjson v0.7.0 // indirect
	github.com/mitchellh/copystructure v1.0.0 // indirect
	github.com/onsi/ginkgo v1.11.0 // indirect
	github.com/onsi/gomega v1.7.0 // indirect
	github.com/prometheus/client_model v0.2.0 // indirect
	github.com/rubenv/sql-migrate v0.0.0-20200429072036-ae26b214fa43 // indirect
	github.com/stretchr/testify v1.4.0
	gopkg.in/alecthomas/kingpin.v2 v2.2.6
	k8s.io/client-go v0.18.3
	k8s.io/helm v2.16.7+incompatible
	k8s.io/kubernetes v1.16.10 // indirect
	k8s.io/utils v0.0.0-20200324210504-a9aa75ae1b89 // indirect
	sigs.k8s.io/yaml v1.2.0 // indirect
)

replace (
	k8s.io/api => k8s.io/api v0.16.10
	k8s.io/apiextensions-apiserver => k8s.io/apiextensions-apiserver v0.16.10
	k8s.io/apimachinery => k8s.io/apimachinery v0.16.11-rc.0
	k8s.io/apiserver => k8s.io/apiserver v0.16.10
	k8s.io/cli-runtime => k8s.io/cli-runtime v0.16.10
	k8s.io/client-go => k8s.io/client-go v0.16.10
	k8s.io/cloud-provider => k8s.io/cloud-provider v0.16.10
	k8s.io/cluster-bootstrap => k8s.io/cluster-bootstrap v0.16.10
	k8s.io/code-generator => k8s.io/code-generator v0.16.11-rc.0
	k8s.io/component-base => k8s.io/component-base v0.16.10
	k8s.io/cri-api => k8s.io/cri-api v0.16.11-rc.0
	k8s.io/csi-translation-lib => k8s.io/csi-translation-lib v0.16.10
	k8s.io/kube-aggregator => k8s.io/kube-aggregator v0.16.10
	k8s.io/kube-controller-manager => k8s.io/kube-controller-manager v0.16.10
	k8s.io/kube-proxy => k8s.io/kube-proxy v0.16.10
	k8s.io/kube-scheduler => k8s.io/kube-scheduler v0.16.10
	k8s.io/kubectl => k8s.io/kubectl v0.16.10
	k8s.io/kubelet => k8s.io/kubelet v0.16.10
	k8s.io/legacy-cloud-providers => k8s.io/legacy-cloud-providers v0.16.10
	k8s.io/metrics => k8s.io/metrics v0.16.10
	k8s.io/node-api => k8s.io/node-api v0.16.10
	k8s.io/sample-apiserver => k8s.io/sample-apiserver v0.16.10
	k8s.io/sample-cli-plugin => k8s.io/sample-cli-plugin v0.16.10
	k8s.io/sample-controller => k8s.io/sample-controller v0.16.10
)
