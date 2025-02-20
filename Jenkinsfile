
pipeline {

    agent none

    stages{
        stage("build result"){
	    agent {
	        docker {
		   image 'node:8.16.0-alpine'
		   args '--user root'
	        }
	    }
            when{
             changeset "**/result/**"
            }
            steps{
                echo 'Compiling result app'
                    dir('result'){
                        sh 'npm install'
                    }
            }
        }

        stage("build vote"){
            agent {
		docker{
			image 'python:2.7-alpine'
			args '--user root'
		} 
	    }
            when{
             changeset "**/vote/**"
            }
            steps{
                echo 'Compiling vote app'
                    dir('vote'){
                        sh 'pip install -r requirements.txt'
                    }
            }
        }

        stage("build worker"){
	    agent {
	        docker {
		   image 'maven:3.6.3-openjdk-17-slim'
		   args '-v $HOME/.m2:/root/.m2'
	        }
	    }
            when{
             changeset "**/worker/**"
            }
            steps{
                echo 'Compiling worker app'
                    dir('worker'){
                        sh 'mvn compile'
                    }
            }
        }

        stage("test result"){
	    agent {
	        docker {
		   image 'node:8.16.0-alpine'
		   args '--user root'
	        }
	    }
              when{
                changeset "**/result/**"
               }
               steps{
                   echo 'Running Unit Tets on result app'
                dir('result'){
                        sh 'npm test'
                }
            }
        }

	stage("test vote"){
	      agent {
		docker{
			image 'python:2.7-alpine'
			args '--user root'
		} 
	      }
              when{
                changeset "**/vote/**"
               }
               steps{
                   echo 'Running Unit Tets on vote app'
                dir('vote'){
                        sh 'pip install -r requirements.txt'
                        sh 'nosetests -v'
                }
            }
        }

        stage("test worker"){
	    agent {
	        docker {
		   image 'maven:3.6.3-openjdk-17-slim'
		   args '-v $HOME/.m2:/root/.m2'
	        }
	    }
              when{
                changeset "**/worker/**"
               }
               steps{
                   echo 'Running Unit Tets on worker app'
                dir('worker'){
                        sh 'mvn clean test'
                }
            }
        }

        stage("package worker"){
	    agent {
	        docker {
		   image 'maven:3.6.3-openjdk-17-slim'
		   args '-v $HOME/.m2:/root/.m2'
	        }
	    }
            when{
                branch 'master'
                changeset "**/worker/**"
             }

            steps{
                echo 'Packaging worker app'
                dir('worker'){
                        sh 'mvn package -DskipTests'
                        archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true
                }
            }
        }

        stage("docker build result"){
	    agent any
            when{
             changeset "**/result/**"
	     branch 'master'
            }
            steps{
	       script {
		    docker.withRegistry("https://index.docker.io/v1/", 'dockerlogin') {
		    def resultImage = docker.build("lauroffecapgemini/result:v${env.BUILD_ID}",'./result')
		    resultImage.push()
		    resultImage.push("${env.BRANCH_NAME}")
		    }
		}
            }
        }

	stage("docker build vote"){
	      agent any
              when{
                changeset "**/vote/**"
		branch 'master'
               }
               steps{
			script {
				docker.withRegistry('https://index.docker.io/v1/', 'dockerlogin') { 
				def voteImage =  docker.build("lauroffecapgemini/vote:v${env.BUILD_ID}", "./vote")
				voteImage.push()
				voteImage.push("${env.BRANCH_NAME}")
				}
			}
               }
        }

        stage("docker build worker"){
	    agent any
            when{
             changeset "**/worker/**"
	     branch 'master'
            }
            steps{
	       script {
		    docker.withRegistry("https://index.docker.io/v1/", 'dockerlogin') {
		    def workerImage = docker.build("lauroffecapgemini/worker:v${env.BUILD_ID}",'./worker')
		    workerImage.push()
		    workerImage.push("${env.BRANCH_NAME}")
		    }
		}
            }
        }

        stage('Sonarqube') {
		agent any
		tools {
			jdk "JDK11" // the name you have given the JDK installation in Global Tool Configuration
		}

		environment{
			sonarpath = tool 'SonarScanner'
		}

		steps {
			echo 'Running Sonarqube Analysis..'
				withSonarQubeEnv('sonar-instavote') {
					sh "${sonarpath}/bin/sonar-scanner -Dproject.settings=sonar-project.properties -Dorg.jenkinsci.plugins.durabletask.BourneShellScript.HEARTBEAT_CHECK_INTERVAL=86400"
				}
		}
        }


        stage("Quality Gate") {
		steps {
			timeout(time: 1, unit: 'HOURS') {
				// Parameter indicates whether to set pipeline to UNSTABLE if Quality Gate fails
				// true = set pipeline to UNSTABLE, false = don't
				waitForQualityGate abortPipeline: true
			}
		}
        }

	stage('deploy to dev'){
	  agent any
            when{
	     branch 'master'
	    }
	  steps{
	    echo 'Deploy instavote app with docker compose'
	    sh 'docker-compose up -d'
	  }
	}
    }
    post{
        always{
            echo 'Building multibranch pipeline for worker is completed..'
        }
    }
}
