APP=dok_tele_status
REGISTRY=dchernenko
VERSION=production

#VERSION=$(shell git describe --tags --abbrev=0 --always)-$(shell git rev-parse --short HEAD)

TARGET_OS=$(shell uname -s | tr '[:upper:]' '[:lower:]') # linux darwin windows

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
	rm -rf dok_tele_status