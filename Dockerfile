FROM golang as builder
WORKDIR /src
COPY . .
RUN go install golang.org/x/lint/golint@latest
RUN make build
#RUN CGO_ENABLED=0 go build -o dok_tele_status 

FROM alpine
COPY --from=builder /src/dok_tele_status .
# copy the ca-certificate.crt from the build stage
#COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
#RUN apk update && apk add --no-cache git ca-certificates && update-ca-certificates
RUN apk add --no-cache ca-certificates && update-ca-certificates
ENTRYPOINT ["/dok_tele_status","start"]
