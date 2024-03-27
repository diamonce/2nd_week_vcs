FROM golang as builder
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -o dok_tele_status 

FROM scratch
COPY --from=builder /src/dok_tele_status .
ENTRYPOINT ["/dok_tele_status","start"]
