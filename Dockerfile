FROM centos:7

LABEL maintainer="Paolo Smiraglia" \
      maintainer.email="paolo.smiraglia@gmail.com"

# add Shibboleth repo
COPY ./etc/yum.repos.d/shibboleth.repo /etc/yum.repos.d/

# install dependencies
RUN yum install -y \
        httpd \
        libxslt \
        mod_php \
        mod_ssl \
        opensaml-bin \
        shibboleth.x86_64 \
    && yum -y clean all

# add static pages
COPY ./var/www/html/access /var/www/html/access
COPY ./var/www/html/whoami /var/www/html/whoami

# add application paths
COPY ./opt/shibboleth-sp /opt/shibboleth-sp
COPY ./opt/spid-metadata /opt/spid-metadata

# add configurations
COPY ./etc/shibboleth/ /etc/shibboleth/
COPY ./etc/httpd/conf.d/ /etc/httpd/conf.d/

# copy bootstrap script
COPY ./usr/local/bin/docker-bootstrap.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-bootstrap.sh

# runit
EXPOSE 80 443
CMD ["docker-bootstrap.sh"]
