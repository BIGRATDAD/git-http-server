# cgit-docker
cgit Docker container.  
Scans for repos at `/srv/git`.

## Running the Container
```bash
docker pull ratdad/cgit
docker run --name cgit -d -p 80:80 -v git/repo/location:/srv/git 
```

You can optionally run with HTTP Basic Auth with these options.
```bash
docker run --name cgit -d -p 80:80 -v git/repo/location:/srv/git -e HTTP_AUTH_PASSWORD=pass HTTP_AUTH_USER=user
``` 

## Docker Build
```bash
# Push-only
docker build --build-arg GIT_HTTP_MODE=w -t cgit:push-only .

# Full RW
docker build --build-arg GIT_HTTP_MODE=rw -t cgit:rw .

# Read-only
docker build --build-arg GIT_HTTP_MODE=ro -t cgit:ro .

# No Git HTTP at all
docker build --build-arg GIT_HTTP_MODE=off -t cgit:no-http .
```

## Docker Compose
You can use Docker Compose to create an instance of the server.
```yaml
#
#
# cgit-docker compose example

name: 'cgit-docker'

services:
  cgit:
    container_name: cgit-docker
    build:
      context: .
      dockerfile: Dockerfile
    # You can also use the pre-built containers hosted at ghcr and docker
    # image: ghcr.io/bigratdad/cgit-docker:latest
    # image: ratdad/cgit-docker:latest
    env_file:
      - .env
    ports:
      - 80:80
    volumes:
      - ./etc/httpd/conf/httpd.conf:/etc/httpd/conf/httpd.conf # you may want to change the httpd config on the server
      - ./etc/cgitrc:/etc/cgitrc # you can (and should) bind your own cgitrc
      - ./opt/:/opt # put your helper scripts in /opt
      - ./srv/git/:/srv/git # bind the location of your git repos to /srv/git in the container
```

## Configuration
There are several areas you may want to configure on this server.

### Runtime Configuration
Runtime configuration is done via a `cgitrc` file placed in `/etc/cgitrc` on the container. If you're using a compose file, you should be able to bind your own `cgitrc` file to that location. See [cgitrc(5)](https://linux.die.net/man/5/cgitrc) for more details on how to write this file for your specific use case.

### Apache Web Server
This container runs Apache Web Server. I made this decision because it's one of the few http servers that has built support for Common Gateway Interface. 

**To configure**, just mount your custom `httpd.conf` to `/etc/httpd/conf/httpd.conf` inside the container. Just keep in mind that cgit is compiled to serve its files in `/srv/www/htdocs/cgit/` and not the default location of `/var/www/htdocs/cgit/` as the documentation states. This is a decision I made deliberately because `/srv/` is where server files should go.

