.DEFAULT_GOAL := deps

deps:
	git submodule update --init

test:
	go run ../lsonnet.go test

validate:
	go run ../lsonnet.go validate

generate:
	go run lsonnet generate \
	--appconfig=${appConfig} \
  --pipelineconfig={}

audit:
	mkdir -p _diffs
	helm list | grep ${chart} | awk '{print $1}' | xargs -I '{}' bash -c "go run ./lsonnet.go migrate '{}' | kubectl diff -f - | tee -a _diffs/'{}'.diff"
