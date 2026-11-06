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
		    sh 'docker build -t $IMAGE .'
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
			  aquasec/trivy:latest image
			  --scanners vuln \
			  --severity HIGH, CRITICAL --ignore-unfixed \
			  --format json --output reports/trivy.json $IMAGE
			docker run --rm \
			  -v /var/run/docker.sock:/var/run/docker.sock \
			  -v trivy-cache:/root/.cache \
			  --volumes-from jenkins -w "$WORKSPACE" \
			  aquasec/trivy:latest image \
			  --scanners vuln \
			  --severity HIGH, CRITICAL --ignore-unfixed \
			  --exit-code 1 $IMAGE
		   '''
	 }
	
	 post {
	     success { echo "Pipeline passed. Image built: ${IMAGE}" }
	     failure { echo "Pipeline failed. Check the stage logs above." }
	     always { archiveArtifacts artifacts: 'reports/*', allowEmptyArchive: true }
	 }
}
