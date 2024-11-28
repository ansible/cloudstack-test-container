FROM quay.io/bedrock/ubuntu:22.04

ENV DEBIAN_FRONTEND noninteractive

ARG src_url=https://github.com/apache/cloudstack/archive/refs/tags/4.19.1.3.tar.gz

RUN echo 'mysql-server mysql-server/root_password password root' | debconf-set-selections; \
    echo 'mysql-server mysql-server/root_password_again password root' | debconf-set-selections;

RUN apt-get -y update && apt-get install -y --no-install-recommends \
    genisoimage \
    libffi-dev \
    libssl-dev \
    sudo \
    ipmitool \
    maven \
    netcat \
    openjdk-11-jdk \
    python3 \
    python3-dev \
    python3-mysql.connector \
    python3-pip \
    python3-setuptools \
    python3-paramiko \
    supervisor \
    wget \
    nginx \
    jq \
    mysql-server \
    openssh-client \
    build-essential \
    npm \
    nodejs \
    && apt-get clean all && rm -rf /var/lib/apt/lists/*;

# TODO: check if and why this is needed
RUN mkdir -p /root/.ssh \
    && chmod 0700 /root/.ssh \
    && ssh-keygen -t rsa -N "" -f id_rsa.cloud

RUN mkdir -p /var/run/mysqld; \
    chown mysql /var/run/mysqld;

RUN (/usr/bin/mysqld_safe &); sleep 5; mysqladmin -u root -proot password ''

RUN wget $src_url -O /opt/cloudstack.tar.gz; \
    mkdir -p /opt/cloudstack; \
    tar xvzf /opt/cloudstack.tar.gz -C /opt/cloudstack --strip-components=1

WORKDIR /opt/cloudstack

RUN ln -s /usr/bin/python3 /usr/local/bin/python
RUN mvn -Pdeveloper -Dsimulator -DskipTests clean install
RUN mvn -Pdeveloper -Dsimulator dependency:go-offline
RUN mvn -pl client jetty:run -Dsimulator -Djetty.skip -Dorg.eclipse.jetty.annotations.maxWait=120

COPY zones.cfg /opt/zones.cfg

RUN (/usr/bin/mysqld_safe &); \
    sleep 5; \
    mvn -Pdeveloper -pl developer -Ddeploydb; \
    mvn -Pdeveloper -pl developer -Ddeploydb-simulator; \
    mvn -Pdeveloper,marvin -pl :cloud-marvin; \
    MARVIN_FILE=$(find /opt/cloudstack/tools/marvin/dist/ -name "Marvin*.tar.gz"); \
    pip install wheel; \
    pip install $MARVIN_FILE;

COPY nginx_default.conf /etc/nginx/sites-available/default
RUN pip install cs
COPY run.sh /opt/run.sh
COPY deploy.sh /opt/deploy.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN cd ui && npm install && npm run build

RUN /opt/deploy.sh

EXPOSE 8888 8080 8096

CMD ["/usr/bin/supervisord"]
