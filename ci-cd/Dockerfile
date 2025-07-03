# Usas la imagen oficial de Jenkins (basada en Debian)
FROM jenkins/jenkins:lts

# Definimos la versión de Terraform como un argumento
ARG TERRAFORM_VERSION=1.9.0

# Cambias a root para instalar todo
USER root

# Recibe el GID del host para sincronizar permisos de Docker
ARG DOCKER_GID
RUN addgroup --gid ${DOCKER_GID} docker

# --- Instalación de TODAS las Herramientas ---
# 1. Instala dependencias, Python, Pip, Docker y herramientas para descargar
RUN apt-get update && \
    apt-get install -y docker.io python3 python3-pip curl unzip && \
    rm -rf /var/lib/apt/lists/*

# 2. Instala Terraform manualmente
RUN curl -LO "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
    unzip "terraform_${TERRAFORM_VERSION}_linux_amd64.zip" && \
    mv terraform /usr/local/bin/ && \
    rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

# 3. Instala las librerías de Python (Checkov y Moto)
RUN pip3 install --no-cache-dir --break-system-packages checkov moto

# --- Configuración de Permisos y Plugins ---
# Agrega el usuario jenkins al grupo 'docker'
RUN usermod -aG docker jenkins

# Copia e instala los plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

# Vuelves al usuario jenkins por seguridad
USER jenkins