#!/bin/bash

PLUGINS_FILE="/usr/share/jenkins/ref/plugins.txt"

jenkins-plugin-cli --plugin-file $PLUGINS_FILE

echo 'Plugins instalados'