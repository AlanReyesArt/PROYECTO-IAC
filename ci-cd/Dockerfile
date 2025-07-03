FROM jenkins/jenkins:lts

ARG DOCKER_GID
USER root

# Crea el grupo docker con el GID del host para evitar errores de permisos
RUN addgroup --gid ${DOCKER_GID} docker

# Instala el CLI de Docker
RUN apt-get update && \
    apt-get install -y docker.io && \
    rm -rf /var/lib/apt/lists/*

# Agrega el usuario jenkins al grupo docker
RUN usermod -aG docker jenkins

# Copia la lista de plugins y la instala
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

USER jenkins