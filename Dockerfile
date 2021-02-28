# build
FROM golang:1.15.2 as builder
ENV GO111MODULE=on
ENV GOROOT=/usr/local/go
ENV GOPATH=/data/apps/go

COPY . $GOPATH/src/goim

WORKDIR $GOPATH/src/goim

RUN mkdir target
RUN cp cmd/comet/comet-example.toml target/comet.toml
RUN cp cmd/logic/logic-example.toml target/logic.toml
RUN	cp cmd/job/job-example.toml target/job.toml

RUN go build -o target/comet cmd/comet/main.go
RUN go build -o target/logic cmd/logic/main.go
RUN go build -o target/job cmd/job/main.go

# final
FROM golang:1.15.2 as final

ENV GOROOT=/usr/local/go
ENV GOPATH=/data/apps/go

ARG env
ENV ENV=${env}

COPY --from=builder $GOPATH/src/goim/target $GOPATH/bin

WORKDIR $GOPATH/bin

CMD ["sh", "-c", "nohup ./logic -conf=./logic.toml -region=sh -zone=sh001 -deploy.env=dev -weight=10 2>&1 > ./logic.log & nohup ./comet -conf=./comet.toml -region=sh -zone=sh001 -deploy.env=dev -weight=10 -addrs=127.0.0.1 -debug=true 2>&1 > ./comet.log & nohup ./job -conf=./job.toml -region=sh -zone=sh001 -deploy.env=dev 2>&1 > ./job.log &"]
EXPOSE 80