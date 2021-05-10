### Configure
```shell
export DENODO_VERSION=20210209
```

### Build Command
```shell
docker build \
    -t ${REGISTRY}/denodo/solman:8.${DENODO_VERSION} \
    --build-arg BASE_REGISTRY=${REGISTRY} \
    --build-arg DENODO_VERSION=${DENODO_VERSION} \
    .
```

### Run Command
```shell
docker run --init -it --rm \
    --name denodo-solman  \
    --network denodo \
    -h localhost \
    -v $(pwd)/denodo.lic:/opt/denodo/license/denodo.lic \
    -v denodo-solman-data:/opt/denodo/metadata/solution-manager/db \
    -v denodo-solman-vdp-data:/opt/denodo/metadata/db \
    -p 10090:10090 \
    -p 10091:10091 \
    -p 19090:19090 \
    -p 19097:19097 \
    -p 19098:19098 \
    -p 19099:19099 \
    -p 19995:19995 \
    -p 19996:19996 \
    -p 19997:19997 \
    -p 19998:19998 \
    -p 19999:19999 \
    ${REGISTRY}/denodo/solman:7.${DENODO_VERSION}
```

### Run SSL Command
```shell
# Having to do all of this to generate a valid key and trust store.
# Just having a self signed key store does not work.
openssl genrsa -out ca.key 2048 && \
openssl req -x509 -new -nodes -key ca.key -subj '/CN=ca' -sha256 -days 365 -out ca.pem && \
openssl genrsa -out localhost.key 2048 && \
openssl req -new -key localhost.key -subj '/CN=localhost' -out localhost.csr && \
openssl x509 -req -in localhost.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out localhost.pem -days 365 -sha256 && \
openssl pkcs12 -export -name localhost -in localhost.pem -inkey localhost.key -out localhost.p12 -passout pass:changeit && \
keytool -importkeystore -srckeystore localhost.p12 -srcstoretype PKCS12 -srcstorepass changeit -deststorepass changeit -destkeystore keystore.jks -deststoretype JKS && \
keytool -importcert -file ca.pem -keystore truststore.jks -alias "ca" -storepass changeit -noprompt -storetype JKS && \
rm -f localhost.* ca.*

docker run --init -it --rm \
    --name denodo-solman  \
    -h localhost \
    -v $(pwd)/keystore.jks:/opt/denodo/conf/keystore.jks \
    -v $(pwd)/truststore.jks:/opt/denodo/conf/truststore.jks \
    -v $(pwd)/denodo.lic:/opt/denodo/conf/denodo.lic \
    -v denodo-solman-data:/metadata/solution-manager/db \
    -v denodo-solman-vdp-data:/opt/denodo/metadata/db \
    -p 10090:10090 \
    -p 10091:10091 \
    -p 19097:19097 \
    -p 19098:19098 \
    -p 19099:19099 \
    -p 19443:19443 \
    -p 19995:19995 \
    -p 19996:19996 \
    -p 19997:19997 \
    -p 19998:19998 \
    -p 19999:19999 \
    -e DENODO_SSL_ENABLED=true \
    -e DENODO_SSL_KEYSTORE=/opt/denodo/conf/keystore.jks \
    -e DENODO_SSL_KEYSTORE_PASSWORD=changeit \
    -e DENODO_SSL_TRUSTSTORE=/opt/denodo/conf/truststore.jks \
    -e DENODO_SSL_TRUSTSTORE_PASSWORD=changeit \
    ${REGISTRY}/denodo/solman:7.${DENODO_VERSION}
```

### Environment Variables
| Variable Name | Description | Default Value |
| --- | --- | --- |
| DENODO_HOSTNAME | This must be set to the external hostname your accessing VDP at. See gotcha below. | localhost |
| DENODO_SSL_ENABLED | | None |
| DENODO_SSL_KEYSTORE | | None |
| DENODO_SSL_KEYSTORE_PASSWORD | | None |
| DENODO_SSL_TRUSTSTORE | | None |
| DENODO_SSL_TRUSTSTORE_PASSWORD | | None |
| DENODO_START_DESIGN_STUDIO | | true |
| DENODO_START_SCHEDULER_WEB_ADMIN | | true |
| DENODO_START_DIAGNOSTIC_AND_MONITORING | | true |
| DENODO_USE_EXTERNAL_METADATA | | false |
| DENODO_STORAGE_CATALOG | | |
| DENODO_STORAGE_DATASOURCE_TESTONBORROW | | true |
| DENODO_STORAGE_DATASOURCE_MAXACTIVE | | 100 |
| DENODO_STORAGE_PLUGIN | | postgresql |
| DENODO_STORAGE_ENCRYPTEDPASSWORD | The Denodo encrypted password. This is currently being generated from DENODO_STORAGE_PASSWORD | |
| DENODO_STORAGE_PASSWORD | Plain-text password. Will be encrypted by Denodo. | |
| DENODO_STORAGE_SHAREDMETADATA | | true |
| DENODO_STORAGE_CLASSPATH | | postgresql-10 |
| DENODO_STORAGE_URI | | jdbc\:postgresql\://postgres\:5432/denodo |
| DENODO_STORAGE_DATASOURCE_INITIALSIZE | | 4 |
| DENODO_STORAGE_DATASOURCE_VALIDATIONQUERY | | Select 1 |
| DENODO_STORAGE_USER | | denodo |
| DENODO_STORAGE_DRIVER | | org.postgresql.Driver |
| DENODO_STORAGE_VERSION | | 10 |
| DENODO_STORAGE_SCHEMA | | |
| DENODO_LICENSE | The license string. You can also just mount the license file instead of passing the text into this environmental variable. | |

### Solution Manager Default Ports
| Server | Default Port |
| --- | --- |
| Server | 10090 |

### License Manager Default Ports
| Server | Default Port |
| --- | --- |
| Server | 10091 |

### Virtual DataPort Default Ports
| Server | Default Port |
| --- | --- |
| Server port (Virtual DataPort administration tool and JDBC port) | 19999 |
| ODBC port | 19996 |
| Monitoring ports (JMX) | Primary port: 19997 (the JMX connection is established with this port)<br /><br />Secondary port: 19995 |
| Shutdown port (only reachable from localhost) | 19998 |

### Denodo Platform Web container (Solution Manager Administration Tool and the Denodo Security Token Service) Default Ports
| Server | Default Port |
| --- | --- |
| Web container port | 19090 for HTTP connections<br /><br />19443 for HTTPS connections |
| Shutdown port (only reachable from localhost) | 19099 |
| Monitoring ports (JMX) | 19098 and 19097 |

### Denodo URLs
| Service | URL |
| --- | --- |
| Solution Manager | HTTP: http://localhost:19090/solution-manager-web-tool <br /> HTTPS: https://localhost:19443/solution-manager-web-tool |
| Design Studio | HTTP: http://localhost:19090/denodo-design-studio/ <br /> HTTPS: https://localhost:19443/denodo-design-studio/ |
| Scheduler Admin | HTTP: http://localhost:19090/webadmin/denodo-scheduler-admin <br /> HTTPS: https://localhost:19443/webadmin/denodo-scheduler-admin |
| Diagnostic & Monitoring Tool | HTTP: http://localhost:19090/diagnostic-monitoring-tool <br /> HTTPS: https://localhost:19443/diagnostic-monitoring-tool |

### Gotchas
Something that will trip you up is how Denodo uses it's hostname. Denodo takes advantage of Java RMI(Remote Method Invocation). RMI has a nasty querk that it only will respond if your request came to the hostname it was expecting. To make sure both internal and external communication works to VDP you need to make sure that you set the ```DENODO_HOSTNAME``` and container hostname to the exact same value as your external connection. So if for example Dendodo is behind a load balancer and the URL is ```denodo.example.org``` then both ```DENODO_HOSTNAME``` and the containers hostname must be ```denodo.example.org``` for everything to work the way your expecting.