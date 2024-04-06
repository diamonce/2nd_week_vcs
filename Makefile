.PHONY: all linux_arm linux

APP=dok_tele_status
#REGISTRY=dchernenko
REGISTRY=europe-central2-docker.pkg.dev/ethereal-runner-417315/dc-docker-repo

VERSION=$(shell git describe --tags --abbrev=0 --always)-$(shell git rev-parse --short HEAD)
#VERSION=production

TARGET_OS=$(shell uname -s | tr '[:upper:]' '[:lower:]' | tr -d ' ' )
# linux darwin windows

ifeq ($(shell uname -m),i386)
	TARGET_ARCH := 386
endif
ifeq ($(shell uname -m),i686)
	TARGET_ARCH := 386
endif
ifeq ($(shell uname -m),x86_64)
	TARGET_ARCH := amd64
endif
ifeq ($(shell uname -m),arm)
	ifeq ($(shell dpkg --print-architecture | grep -q "arm64" && echo "arm64"), arm64)
		TARGET_ARCH := arm64
	else
		TARGET_ARCH := arm
	endif
endif

# Force override
TARGET_OS=linux
TARGET_ARCH=amd64
#export TARGET_ARCH
 
all: linux linux_arm 
#linux_arm 
#darwin  
#windows

linux: set_linux image push 
linux_arm: set_linux_arm image push

darwin: set_darwin image push 
darwin_arm: set_darwin_arm image push

windows: set_windows image push 

set_linux: 
	 $(eval TARGET_OS := linux)
	 $(eval TARGET_ARCH := amd64)

set_linux_arm: 
	 $(eval TARGET_OS := linux)
	 $(eval TARGET_ARCH := arm64)

set_darwin: 
	 $(eval TARGET_OS := darwin)
	 $(eval TARGET_ARCH := amd64)

set_darwin_arm: 
	 $(eval TARGET_OS := darwin)
	 $(eval TARGET_ARCH := arm64)	

set_windows: 
	 $(eval TARGET_OS := windows)
	 $(eval TARGET_ARCH := x86_64)

format:
	gofmt -s -w ./

lint:
	golint ./...

test:
	go test -v

debug:
	echo "App version: ${VERSION}"
	echo "Target architecture: ${TARGET_ARCH}"
	echo "Target OS: ${TARGET_OS}"

config:
	go get

build: debug format lint test config
	CGO_ENABLED=0 GOOS=${TARGET_OS} GOARCH=${TARGET_ARCH} go build -v -o dok_tele_status -ldflags "-X="github.com/diamonce/dok_tele_status/cmd.appVersion=${VERSION}

image:
	echo "Building ${REGISTRY}/${APP}:${VERSION}-${TARGET_ARCH}"
#	docker build -t ${REGISTRY}/${APP}:${VERSION}-${TARGET_ARCH} -f Dockerfile .
	docker buildx build --platform ${TARGET_OS}/${TARGET_ARCH} -t ${REGISTRY}/${APP}:${VERSION}-${TARGET_ARCH} -f Dockerfile .

push:
	docker push ${REGISTRY}/${APP}:${VERSION}-${TARGET_ARCH}

clean:
	rm -rf ${APP}
	docker rmi ${REGISTRY}/${APP}:${VERSION}-${TARGET_ARCH}