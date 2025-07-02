# Usas la imagen oficial de Jenkins
FROM jenkins/jenkins:lts

# Cambias a root para instalar el CLI de Docker (necesario para hablar con el socket)
USER root

ARG DOCKER_GID
RUN addgroup --gid ${DOCKER_GID} docker

RUN apt-get update && \
    apt-get install -y docker.io && \
    rm -rf /var/lib/apt/lists/*

# Agregas el usuario jenkins al grupo docker para que pueda usar el socket
RUN usermod -aG docker jenkins

# --- Instalación de Plugins como Código ---
# Copia la lista de plugins que definiste
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
# Ejecuta el script de instalación que viene en la imagen de Jenkins
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

# Vuelves al usuario jenkins
USER jenkins