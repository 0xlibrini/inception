FROM debian:bullseye

RUN apt update && apt install -y mariadb-server

COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

COPY tools/setup.sh /scripts/

RUN chmod +x /scripts/setup.sh

EXPOSE 3306

ENTRYPOINT [ "bash" ]