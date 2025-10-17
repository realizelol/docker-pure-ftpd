# docker-pure-ftpd
Pure-FTPd on Alpine Linux

### Example docker-compose.yaml:
```yaml
services:
  pureftpd:
    image: realizelol/pure-ftpd
    container_name: pure-ftpd
    ports:
      - "21000:21000"
      - "21001-21011"
    volumes:
      - "./data:/pure-ftpd/data"
      - "./ftp:/pure-ftpd/ftp"
    environment:
      - "TZ=Europe/Berlin"
      - "PASSIVE_IP=192.168.100.12"
    restart: always
```
