pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    some-label: jenkins-kaniko
spec:
  serviceAccountName: jenkins-sa
  containers:
    - name: awscli
      image: amazon/aws-cli:2.15.0
      command: ["sh", "-c", "sleep 99d"]
    - name: kaniko
      image: gcr.io/kaniko-project/executor:v1.16.0-debug
      command: ["sh", "-c", "sleep 99d"]
    - name: git
      image: alpine/git
      command: ["sh", "-c", "sleep 99d"]
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
          withCredentials([usernamePassword(credentialsId: 'aws-credentials', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
            sh '''
              mkdir -p /kaniko/.docker

              aws ecr get-login-password --region $AWS_REGION | \
                /busybox/sh -c "cat > /tmp/ecr_pass"

              # Create docker config.json for Kaniko:
              PASS=$(cat /tmp/ecr_pass)
              AUTH=$(echo -n "AWS:${PASS}" | base64 | tr -d '\\n')

              cat > /kaniko/.docker/config.json <<EOF
              {
                "auths": {
                  "${ECR_REGISTRY}": {
                    "auth": "${AUTH}"
                  }
                }
              }
EOF
            '''
          }
        }
      }
    }

    stage('Build & Push Docker Image') {
      steps {
        container('kaniko') {
          sh '''
            /kaniko/executor \
              --context `pwd` \
              --dockerfile `pwd`/Dockerfile \
              --destination=$ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG \
              --cache=true
          '''
        }
      }
    }

    stage('Update Helm values.yaml in chart repo') {
      steps {
        container('git') {
          withCredentials([usernamePassword(credentialsId: 'github-token', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PAT')]) {
            sh '''
              rm -rf chart-repo
              git clone https://$GIT_USERNAME:$GIT_PAT@$CHART_REPO_URL chart-repo
              cd chart-repo/$CHART_PATH

              sed -i "s|repository: .*|repository: $ECR_REGISTRY/$IMAGE_NAME|g" values.yaml
              sed -i "s|tag: .*|tag: $IMAGE_TAG|g" values.yaml

              git config user.email "$COMMIT_EMAIL"
              git config user.name "$COMMIT_NAME"

              git add values.yaml
              git commit -m "Update image to $ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG" || echo "No changes to commit"
              git push origin main
            '''
          }
        }
      }
    }
  }
}
