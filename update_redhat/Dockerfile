FROM redhat/ubi8

LABEL maintainer="geniandersonl@gmail.com"
LABEL description="Esta é uma imagem Docker é para teste de atualização do php"
LABEL version="1.0"

RUN yum update && yum install -y httpd


EXPOSE 8080
EXPOSE 8443

RUN yum -y update

CMD ["tail", "-f", "/dev/null"]