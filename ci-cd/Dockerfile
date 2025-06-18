FROM jenkins/jenkins:lts

USER root

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt 
COPY install-plugins.sh /usr/local/bin/install-plugins.sh

RUN chmod +x /usr/local/bin/install-plugins.sh \
 && install-plugins.sh