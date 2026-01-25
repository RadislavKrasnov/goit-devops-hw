pipeline {
  agent {
    kubernetes {
      cloud 'kubernetes'
      defaultContainer 'jnlp'

      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: jenkins-kaniko
spec:
  serviceAccountName: jenkins-sa
  restartPolicy: Never

  volumes:
    - name: workspace-volume
      emptyDir: {}
    - name: kaniko-docker-config
      emptyDir: {}

  containers:
    - name: jnlp
      image: jenkins/inbound-agent:3309.v27b_9314fd1a_4-1
      args: ['\$(JENKINS_SECRET)', '\$(JENKINS_NAME)']
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent

    - name: awscli
      image: amazon/aws-cli:2.15.0
      command: ["sh", "-c", "sleep 99d"]
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent
        - name: kaniko-docker-config
          mountPath: /kaniko/.docker

    - name: kaniko
      image: gcr.io/kaniko-project/executor:v1.16.0-debug
      command: ["sh", "-c", "sleep 99d"]
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent
        - name: kaniko-docker-config
          mountPath: /kaniko/.docker

    - name: git
      image: alpine/git
      command: ["sh", "-c", "sleep 99d"]
      volumeMounts:
        - name: workspace-volume
          mountPath: /home/jenkins/agent
"""
    }
  }

  environment {
    AWS_REGION   = "us-east-1"

    ECR_REGISTRY = "269416271884.dkr.ecr.us-east-1.amazonaws.com"
    IMAGE_NAME   = "lesson-5-ecr"
    IMAGE_TAG    = "v1.0.${BUILD_NUMBER}"

    CHART_REPO_URL = "github.com/RadislavKrasnov/goit-devops-charts.git"
    CHART_PATH     = "charts/django-app"

    COMMIT_EMAIL = "jenkins@localhost"
    COMMIT_NAME  = "jenkins"
  }

  stages {

    stage('Prepare ECR auth for Kaniko') {
      steps {
        container('awscli') {
          withCredentials([
            usernamePassword(
              credentialsId: 'aws-credentials',
              usernameVariable: 'AWS_ACCESS_KEY_ID',
              passwordVariable: 'AWS_SECRET_ACCESS_KEY'
            )
          ]) {
            sh '''
              set -e
              echo "Preparing ECR auth for Kaniko..."

              PASS="$(aws ecr get-login-password --region $AWS_REGION)"
              AUTH="$(printf "AWS:%s" "$PASS" | base64 | tr -d '\\n')"

              cat > /kaniko/.docker/config.json <<EOF
              {
                "auths": {
                  "${ECR_REGISTRY}": {
                    "auth": "${AUTH}"
                  }
                }
              }
EOF

              echo "ECR auth prepared successfully"
            '''
          }
        }
      }
    }

    stage('Build & Push Docker Image') {
      steps {
        container('kaniko') {
          sh '''
            set -e
            echo "Building and pushing image with Kaniko..."

            /kaniko/executor \
              --context $(pwd) \
              --dockerfile $(pwd)/Dockerfile \
              --destination=$ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG \
              --cache=true

            echo "Image pushed: $ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
          '''
        }
      }
    }

    stage('Update Helm values.yaml in chart repo') {
      steps {
        container('git') {
          withCredentials([
            usernamePassword(
              credentialsId: 'github-token',
              usernameVariable: 'GIT_USERNAME',
              passwordVariable: 'GIT_PAT'
            )
          ]) {
            sh '''
              set -e
              echo "Cloning chart repository..."

              rm -rf chart-repo
              git clone https://$GIT_USERNAME:$GIT_PAT@$CHART_REPO_URL chart-repo
              cd chart-repo/$CHART_PATH

              echo "Updating values.yaml..."
              sed -i "s|repository: .*|repository: $ECR_REGISTRY/$IMAGE_NAME|g" values.yaml
              sed -i "s|tag: .*|tag: $IMAGE_TAG|g" values.yaml

              git config user.email "$COMMIT_EMAIL"
              git config user.name "$COMMIT_NAME"

              git add values.yaml
              git commit -m "Update image to $ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG" || echo "No changes"
              git push origin main

              echo "Helm values updated successfully"
            '''
          }
        }
      }
    }
  }
}
