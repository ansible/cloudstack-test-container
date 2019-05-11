
FROM ubuntu:xenial-20190425

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update && apt-get install -y \
mysql-server \
&& apt-get clean all \
&& rm -rf /var/lib/apt/lists/*;

RUN mkdir -p /opt/cloudstack

WORKDIR /opt/cloudstack

RUN mkdir -p /var/run/mysqld && \
chown mysql /var/run/mysqld && \
echo '''sql_mode = "STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"''' >> /etc/mysql/mysql.conf.d/mysqld.cnf

RUN find /etc/mysql/ -name '*.cnf' -print0 \
| xargs -0 grep -lZE '^(bind-address|log)' \
| xargs -rt -0 sed -Ei 's/^(bind-address|log)/#&/' \
&& echo '[mysqld]\nskip-host-cache\nbind-address = 0.0.0.0' > /etc/mysql/conf.d/docker.cnf

RUN (/usr/bin/mysqld_safe &); \
    sleep 5; \
    cat /var/log/mysql/*

# RUN /opt/deploy.sh

# EXPOSE 8888 8080 8096

# CMD ["/usr/bin/supervisord"]
