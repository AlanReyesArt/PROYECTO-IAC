pipeline {
    agent {
        label 'terraform-agent'
    }

    stages {
        stage('1. Checkout') {
            steps {
                checkout scm
            }
        }

        // --- Etapas que requieren credenciales ---
        stage('2. Security Scan & Tests') {
            steps {
                // El wrapper 'withCredentials' va DENTRO del bloque 'steps'
                withCredentials([aws(credentialsId: 'aws-terraform-credentials', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    
                    script {
                        echo "--- Ejecutando Security Scan (Checkov) ---"
                        sh 'checkov --directory . --framework terraform || true'
                        
                        echo "\n--- Ejecutando Unit Tests ---"
                        sh 'python3 -m unittest discover tests'
                    }
                }
            }
        }

        stage('3. Terraform Plan & Deploy') {
            steps {
                // El wrapper se vuelve a usar para las etapas de terraform
                withCredentials([aws(credentialsId: 'aws-terraform-credentials', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        // Se define la región como variable de entorno
                        env.AWS_REGION = 'us-east-2'

                        echo "--- Inicializando y Validando Terraform ---"
                        sh 'terraform init -input=false'
                        sh 'terraform fmt -check'
                        sh 'terraform validate'
                        
                        echo "\n--- Creando Plan de Terraform ---"
                        sh 'terraform plan -no-color -out=tfplan'

                        // La lógica para desplegar solo en la rama 'develop'
                        if (env.BRANCH_NAME == 'develop') {
                            timeout(time: 5, unit: 'MINUTES') {
                                input message: '¿Aprobar el despliegue en AWS?', submitter: 'admin'
                            }
                            echo "\n--- Aplicando Plan de Terraform ---"
                            sh 'terraform apply -input=false "tfplan"'
                        } else {
                            echo "Despliegue omitido: No es la rama 'develop'."
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo '>> Limpiando workspace...'
            deleteDir()
        }
    }
}