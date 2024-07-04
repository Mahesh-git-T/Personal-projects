pipeline {
    agent any
    triggers {
        githubPush()
    }
    stages {
        stage('Build') {
            steps {
                git 'https://github.com/Mahesh-git-T/personal-projects.git'
                sh 'docker build -t my-app .'
                sh 'docker tag myapp:latest $REGISTRY_URL/myapp:latest'
                sh 'docker push https://hub.docker.com/repository/docker/mahesht2000/personal_project/myapp:latest'
            }
        }
        stage('Test') {
            steps {
                sh 'docker run -d -p 8081:80 my-app'
                sh 'curl http://localhost:8081' // Simple test to check if app is running
                sh 'docker stop $(docker ps -aq)'
            }
        }
        stage('Deploy') {
            steps {
                kubernetesDeploy(
                    configs: 'deployment.yaml',
                    enableConfigSubstitution: true,
                    kubeconfigId: 'your-kubeconfig-id',
                    enableDeployment: true
                )
            }
        }
    }
}