FROM registry.access.redhat.com/ubi9/go-toolset:9.7-1764620329

COPY . .
RUN go mod download

RUN go build -buildvcs=false -o ./main

FROM registry.access.redhat.com/ubi9/ubi-micro:latest

COPY --from=0 /opt/app-root/src/main ./main

ENV PORT 8081
EXPOSE 8081

CMD [ "./main" ]
