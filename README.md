[![Docker Repository on Quay.io](https://quay.io/repository/sameersbn/invoiceplane/status "Docker Repository on Quay.io")](https://quay.io/repository/sameersbn/invoiceplane)

# sameersbn/invoiceplane:1.4.3-4

- [Introduction](#introduction)
  - [Contributing](#contributing)
  - [Issues](#issues)
- [Getting started](#getting-started)
  - [Installation](#installation)
  - [Quickstart](#quickstart)
  - [Persistence](#persistence)
- [Maintenance](#maintenance)
  - [Upgrading](#upgrading)
  - [Shell Access](#shell-access)

# Introduction

`Dockerfile` to create a [Docker](https://www.docker.com/) container image for [InvoicePlane](https://invoiceplane.com/).

InvoicePlane is a self-hosted open source application for managing your quotes, invoices, clients and payments.

## Contributing

If you find this image useful here's how you can help:

- Send a pull request with your awesome features and bug fixes
- Help users resolve their [issues](../../issues?q=is%3Aopen+is%3Aissue).
- Support the development of this image with a [donation](http://www.damagehead.com/donate/)

## Issues

Before reporting your issue please try updating Docker to the latest version and check if it resolves the issue. Refer to the Docker [installation guide](https://docs.docker.com/installation) for instructions.

SELinux users should try disabling SELinux using the command `setenforce 0` to see if it resolves the issue.

If the above recommendations do not help then [report your issue](../../issues/new) along with the following information:

- Output of the `docker version` and `docker info` commands
- The `docker run` command or `docker-compose.yml` used to start the image. Mask out the sensitive bits.
- Please state if you are using [Boot2Docker](http://www.boot2docker.io), [VirtualBox](https://www.virtualbox.org), etc.

# Getting started

## Installation

Automated builds of the image are available on [Dockerhub](https://hub.docker.com/r/sameersbn/invoiceplane) and is the recommended method of installation.

> **Note**: Builds are also available on [Quay.io](https://quay.io/repository/sameersbn/invoiceplane)

```bash
docker pull sameersbn/invoiceplane:1.4.3-4
```

Alternatively you can build the image yourself.

```bash
docker build -t sameersbn/invoiceplane github.com/sameersbn/docker-invoiceplane
```

## Quickstart

The quickest way to start this image is using [docker-compose](https://docs.docker.com/compose/).

> Update the `INVOICE_PLANE_FQDN` and `INVOICE_PLANE_TIMEZONE` environment variables in the `docker-compose.yml` file as required.

```bash
wget https://raw.githubusercontent.com/sameersbn/docker-invoiceplane/master/docker-compose.example.yml -O docker-compose.yml
docker-compose up
```

In addition to the InvoicePlane container, MySQL and NGINX containers are also started to provide the infrastructure required to get InvoicePlane up and running.

Alternatively, you can start InvoicePlance and the supporting MySQL and NGINX containers manually using the Docker command line.

Step 1. Launch a MySQL container

```bash
docker run --name invoiceplane-mysql -d --restart=always \
  --env 'DB_NAME=invoiceplane_db' \
  --env 'DB_USER=invoiceplane' --env 'DB_PASS=passw0rd' \
  --volume /srv/docker/invoiceplane/mysql:/var/lib/mysql \
  sameersbn/mysql:latest
```

Step 2. Launch the InvoicePlane container

```bash
docker run --name invoiceplane -d --restart=always \
  --link invoiceplane-mysql:mysql \
  --env 'INVOICE_PLANE_FQDN=invoice.example.com' \
  --env 'INVOICE_PLANE_TIMEZONE=Asia/Kolkata' \
  --volume /srv/docker/invoiceplane/invoiceplane:/var/lib/invoiceplane \
  --volume /srv/docker/invoiceplane/nginx/sites-enabled:/etc/nginx/sites-enabled \
  sameersbn/invoiceplane:1.4.3-4
```

Step 3. Launch a NGINX container

```bash
docker run --name invoiceplane-nginx -d --restart=always \
  --link invoiceplane:invoiceplane-php-fpm \
  --volume /srv/docker/invoiceplane/nginx/sites-enabled:/etc/nginx/sites-enabled \
  --volumes-from invoiceplane \
  --publish 10080:80 \
  sameersbn/nginx:1.8.0-10
```

Point your browser to [http://localhost:10080/setup](http://localhost:10080/setup) to complete the setup and start using InvoicePlane.

## Persistence

For InvoicePlane to preserve its state across container shutdown and startup you should mount a volume at `/var/lib/invoiceplane`.

> *The [Quickstart](#quickstart) command already mounts a volume for persistence.*

SELinux users should update the security context of the host mountpoint so that it plays nicely with Docker:

```bash
mkdir -p /srv/docker/invoiceplane
chcon -Rt svirt_sandbox_file_t /srv/docker/invoiceplane
```

# Maintenance

## Upgrading

To upgrade to newer releases:

  1. Download the updated Docker image:

  ```bash
  docker pull sameersbn/invoiceplane:1.4.3-4
  ```

  2. Stop the currently running image:

  ```bash
  docker stop invoiceplane
  ```

  3. Remove the stopped container

  ```bash
  docker rm -v invoiceplane
  ```

  4. Start the updated image

  ```bash
  docker run -name invoiceplane -d \
    [OPTIONS] \
    sameersbn/invoiceplane:1.4.3-4
  ```

## Shell Access

For debugging and maintenance purposes you may want access the containers shell. If you are using Docker version `1.3.0` or higher you can access a running containers shell by starting `bash` using `docker exec`:

```bash
docker exec -it invoiceplane bash
```
