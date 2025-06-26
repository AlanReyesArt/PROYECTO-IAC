FROM jenkins/jenkins:lts

# Cambiar a usuario root para instalar dependencias
USER root

# Instalar Docker CLI para que Jenkins pueda comunicarse con Docker
RUN apt-get update && \
    apt-get install -y docker.io && \
    rm -rf /var/lib/apt/lists/*

# Agregar el usuario jenkins al grupo docker
RUN usermod -aG docker jenkins

# Copiar archivos de configuración
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt 
COPY install-plugins.sh /usr/local/bin/install-plugins.sh
COPY jenkins.yaml /var/jenkins_home/casc_configs/jenkins.yaml

# Hacer ejecutable el script y instalar plugins
RUN chmod +x /usr/local/bin/install-plugins.sh && \
    /usr/local/bin/install-plugins.sh

# Variable de entorno para Configuration as Code
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc_configs/jenkins.yaml

# Volver al usuario jenkins
USER jenkins