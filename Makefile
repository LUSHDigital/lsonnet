.DEFAULT_GOAL := go-build

docker-build:
	docker build . -t lsonnet

go-build:
	go build \
		-ldflags "-X main.version=dev" \
		-o ./bin/lsonnet .

test:
	go test ./... -v

generate:
	go run lsonnet generate \
	--appconfig=${appConfig} \
  --pipelineconfig={}

audit:
	mkdir -p _diffs
	helm list | grep ${chart} | awk '{print $1}' | xargs -I '{}' bash -c "go run ./lsonnet.go migrate '{}' | kubectl diff -f - | tee -a _diffs/'{}'.diff"
