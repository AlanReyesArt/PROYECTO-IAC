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
        
        stage('2. Setup Tools') {
            steps {
                script {
                    echo '>> Instalando herramientas necesarias...'
                    sh 'apk add --no-cache python3 py3-pip && pip3 install checkov moto'
                }
            }
        }

        // --- Inicio del bloque que necesita credenciales de AWS ---
        stage('3. AWS Operations') {
            // Este es el bloque de MEJORES PRÁCTICAS
            withCredentials([aws(credentialsId: 'aws-terraform-credentials', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                
                stage('3.1 Security Scan (Checkov)') {
                    steps {
                        echo '>> Ejecutando escaneo de seguridad de IaC...'
                        sh 'checkov --directory . --framework terraform || true'
                    }
                }

                stage('3.2 Unit Tests') {
                    steps {
                        echo '>> Ejecutando pruebas unitarias de Python...'
                        sh 'python3 -m unittest discover tests'
                    }
                }

                stage('3.3 Terraform Validate & Plan') {
                    steps {
                        script {
                            env.AWS_REGION = 'us-east-2' // Se define la región aquí
                            echo '>> Validando y planeando la infraestructura...'
                            sh 'terraform init -input=false'
                            sh 'terraform fmt -check'
                            sh 'terraform validate'
                            sh 'terraform plan -no-color -out=tfplan'
                        }
                    }
                }

                stage('3.4 Approve & Deploy to AWS') {
                    when { branch 'main' }
                    steps {
                        timeout(time: 5, unit: 'MINUTES') {
                            input message: '¿Aprobar el despliegue en AWS?', submitter: 'admin'
                        }
                        script {
                            env.AWS_REGION = 'us-east-2'
                            echo '>> Aplicando plan de Terraform en AWS...'
                            sh 'terraform apply -input=false "tfplan"'
                        }
                    }
                }

            } // --- Fin del bloque withCredentials ---
        }
    }
    
    post {
        always {
            echo '>> Limpiando workspace...'
            deleteDir()
        }
    }
}