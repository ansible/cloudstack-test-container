FROM ubuntu:focal-20210609

ENV DEBIAN_FRONTEND noninteractive

ARG src_url=https://github.com/apache/cloudstack/archive/4.15.1.0.tar.gz

RUN echo 'mysql-server mysql-server/root_password password root' | debconf-set-selections; \
    echo 'mysql-server mysql-server/root_password_again password root' | debconf-set-selections;

RUN apt-get -qq update && apt-get -qq dist-upgrade && apt-get install -qq -y --no-install-recommends \
    genisoimage \
    libffi-dev \
    libssl-dev \
    sudo \
    ipmitool \
    maven \
    netcat \
    openjdk-11-jdk \
    python3-dev \
    python3-mysql.connector \
    python3-pip \
    python3-setuptools \
    python3-paramiko \
    python2 \
    supervisor \
    wget \
    nginx \
    jq \
    mysql-server \
    openssh-client \
    && apt-get clean all \
    && rm -rf /var/lib/apt/lists/*;


RUN ln -s /usr/bin/python2 /usr/bin/python && python --version

# TODO: check if and why this is needed
RUN mkdir -p /root/.ssh \
    && chmod 0700 /root/.ssh \
    && ssh-keygen -t rsa -N "" -f id_rsa.cloud

 RUN mkdir -p /var/run/mysqld; \
     chown mysql /var/run/mysqld;
# Still needed?
#      echo '''sql_mode = "STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"''' >> /etc/mysql/mysql.conf.d/mysqld.cnf

RUN (/usr/bin/mysqld_safe &); sleep 5; mysqladmin -u root -proot password ''

RUN wget $src_url -O /opt/cloudstack.tar.gz; \
    mkdir -p /opt/cloudstack; \
    tar xvzf /opt/cloudstack.tar.gz -C /opt/cloudstack --strip-components=1

WORKDIR /opt/cloudstack

RUN mvn -Pdeveloper -Dsimulator -DskipTests clean install
RUN mvn -Pdeveloper -Dsimulator dependency:go-offline
RUN mvn -pl client jetty:run -Dsimulator -Djetty.skip -Dorg.eclipse.jetty.annotations.maxWait=120

RUN (/usr/bin/mysqld_safe &); \
    sleep 5; \
    mvn -Pdeveloper -pl developer -Ddeploydb; \
    mvn -Pdeveloper -pl developer -Ddeploydb-simulator; \
    MARVIN_FILE=$(find /opt/cloudstack/tools/marvin/dist/ -name "Marvin*.tar.gz"); \
    pip3 install $MARVIN_FILE;

COPY zones.cfg /opt/zones.cfg
COPY nginx_default.conf /etc/nginx/sites-available/default
RUN pip3 install cs
COPY run.sh /opt/run.sh
COPY deploy.sh /opt/deploy.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN /opt/deploy.sh

EXPOSE 8888 8080 8096

CMD ["/usr/bin/supervisord"]
