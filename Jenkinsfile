pipeline {
	agent any

	environment {
	    IMAGE = "secure-app:${env.BUILD_NUMBER}"
	}

	stages {
	    stage('Checkout') {
		steps {
		    checkout scm
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
	 }
	
	 post {
	     success { echo "Pipeline passed. Image built: ${IMAGE}" }
	     failure { echo "Pipeline failed. Check the stage logs above." }
	 }
}
