pipeline {
    agent any

    environment {
        IMAGE = "secure-app:${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'rm -rf reports && mkdir reports'
            }
        }

        stage('Secret Scan (Gitleaks)') {
            steps {
                sh '''
                    docker run --rm --volumes-from jenkins \
                      -u "$(id -u):$(id -g)" -w "$WORKSPACE" \
                      zricethezav/gitleaks:latest detect --source . --no-git --redact -v \
                      --report-format json --report-path reports/gitleaks.json
                '''
            }
        }

        stage('Dockerfile Lint (Hadolint)') {
            steps {
                sh 'docker run --rm -i hadolint/hadolint hadolint --failure-threshold warning - < Dockerfile'
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'docker build --target test -t secure-app:test .'
            }
        }

        stage('Build Image') {
            steps {
                sh 'docker build --pull -t $IMAGE .'
                sh 'docker images secure-app'
            }
        }

        stage('Image Scan (Trivy)') {
            steps {
                sh '''
                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      -v trivy-cache:/root/.cache \
                      --volumes-from jenkins -w "$WORKSPACE" \
                      aquasec/trivy:latest image \
                      --scanners vuln \
                      --severity HIGH,CRITICAL --ignore-unfixed \
                      --format json --output reports/trivy.json $IMAGE

                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      -v trivy-cache:/root/.cache \
                      --volumes-from jenkins -w "$WORKSPACE" \
                      aquasec/trivy:latest image \
                      --scanners vuln \
                      --severity HIGH,CRITICAL --ignore-unfixed \
                      --exit-code 1 $IMAGE
                '''
            }
        }

        stage('Code Quality (SonarQube)') {
            steps {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                        docker run --rm --network jenkins_default \
                          --volumes-from jenkins -w "$WORKSPACE" \
                          -e SONAR_HOST_URL=http://sonarqube:9000 \
                          -e SONAR_TOKEN="$SONAR_TOKEN" \
                          sonarsource/sonar-scanner-cli:latest \
                          -Dsonar.qualitygate.wait=true \
                          -Dsonar.qualitygate.timeout=300
                    '''
                }
            }
        }

        stage('Push Image') {
            when { branch 'main' }
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub',
                                                  usernameVariable: 'DH_USER',
                                                  passwordVariable: 'DH_PASS')]) {
                    sh '''
                        echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                        docker tag $IMAGE $DH_USER/secure-app:$BUILD_NUMBER
                        docker tag $IMAGE $DH_USER/secure-app:latest
                        docker push $DH_USER/secure-app:$BUILD_NUMBER
                        docker push $DH_USER/secure-app:latest
                        docker logout
                    '''
                }
            }
        }
    }

    post {
        always { archiveArtifacts artifacts: 'reports/*', allowEmptyArchive: true }
        success { echo "Pipeline passed. Image built: ${IMAGE}" }
        failure { echo "Pipeline failed. Check the stage logs above." }
    }
}
