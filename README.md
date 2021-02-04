### Configure
```shell
export DENODO_VERSION=20200803
```

### Build Command
```shell
docker build \
    --progress plain \
    -t ${REGISTRY}/denodo/solman:7.${DENODO_VERSION} \
    --build-arg BASE_REGISTRY=${REGISTRY} \
    --build-arg DENODO_VERSION=${DENODO_VERSION} \
    .
```