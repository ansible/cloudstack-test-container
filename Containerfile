# See https://github.com/apache/cloudstack/blob/main/tools/docker/Dockerfile
FROM docker.io/apache/cloudstack-simulator:4.23.0.0

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    wget \
    nginx \
    jq \
    pipx \
    netcat-traditional \
    && apt-get clean all && rm -rf /var/lib/apt/lists/*;

COPY zones.cfg /opt/zones.cfg

COPY nginx_default.conf /etc/nginx/sites-available/default

RUN pipx install cs

COPY run.sh /opt/run.sh
COPY deploy.sh /opt/deploy.sh
COPY supervisord_nginx.conf /etc/supervisor/conf.d/nginx.conf

RUN /opt/deploy.sh

EXPOSE 8888 8080 8096

CMD ["/usr/bin/supervisord"]
