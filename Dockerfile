FROM maven:3.6-jdk-8-slim as builder

ARG src_url=https://github.com/apache/cloudstack/archive/4.12.0.0.tar.gz

RUN apt-get -y update && apt-get install -y wget python

RUN mkdir -p /opt/cloudstack

RUN wget $src_url -O /opt/cloudstack.tar.gz && \
    tar xvzf /opt/cloudstack.tar.gz -C /opt/cloudstack --strip-components=1

WORKDIR /opt/cloudstack

RUN mvn -Pdeveloper -Dsimulator -DskipTests clean install
RUN mvn -Pdeveloper -Dsimulator dependency:go-offline
RUN mvn -pl client jetty:run -Dsimulator -Djetty.skip -Dorg.eclipse.jetty.annotations.maxWait=120


FROM ubuntu:xenial-20190425

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update && apt-get install -y \
genisoimage \
libffi-dev \
libssl-dev \
sudo \
ipmitool \
maven \
netcat \
openjdk-8-jdk \
python-dev \
python-mysql.connector \
python-pip \
python-setuptools \
supervisor \
nginx \
jq \
mysql-server \
openssh-client \
&& apt-get clean all \
&& rm -rf /var/lib/apt/lists/*;

RUN mkdir -p /opt/cloudstack

WORKDIR /opt/cloudstack

COPY --from=builder /opt/cloudstack /opt/cloudstack
COPY --from=builder /root/.m2 /root/.m2

RUN mkdir -p /var/run/mysqld && \
chown mysql /var/run/mysqld && \
echo '''sql_mode = "STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"''' >> /etc/mysql/mysql.conf.d/mysqld.cnf

COPY zones.cfg /opt/zones.cfg
COPY nginx_default.conf /etc/nginx/sites-available/default
RUN pip install cs==2.5
COPY run.sh /opt/run.sh
COPY deploy.sh /opt/deploy.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN mvn -P developer -pl :cloud-marvin

RUN find /etc/mysql/ -name '*.cnf' -print0 \
| xargs -0 grep -lZE '^(bind-address|log)' \
| xargs -rt -0 sed -Ei 's/^(bind-address|log)/#&/' \
&& echo '[mysqld]\nskip-host-cache' > /etc/mysql/conf.d/docker.cnf

RUN (/usr/bin/mysqld_safe &); \
    sleep 5; \
    mvn -Pdeveloper -pl developer -Ddeploydb; \
    mvn -Pdeveloper -pl developer -Ddeploydb-simulator; \
    MARVIN_FILE=$(find /opt/cloudstack/tools/marvin/dist/ -name "Marvin*.tar.gz"); \
    pip install $MARVIN_FILE;

RUN cat /var/log/mysql/error.log

RUN /opt/deploy.sh

EXPOSE 8888 8080 8096

CMD ["/usr/bin/supervisord"]
