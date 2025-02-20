def kubeAgent = """
    apiVersion: v1
    kind: Pod
    metadata:
      name: dbt-dremio-testing
      labels:
        app: dbt-dremio-testing
    spec:
      containers:
      - name: minio
        image: minio/minio
        args:
        - server
        - /data
        - --console-address
        - ":9001"
        env:
        - name: MINIO_ROOT_USER
          value: "admin"
        - name: MINIO_ROOT_PASSWORD
          value: "password"
        ports:
        - containerPort: 9000
        - containerPort: 9001
        volumeMounts:
        - name: data
          mountPath: /data
        volumes:
        - name: data
          emptyDir: {}
      - name: dremio
        image: dremio/dremio-oss
        env:
        - name: DREMIO_JAVA_SERVER_EXTRA_OPTS
          value: "-Ddebug.addDefaultUser=true"
        ports:
        - containerPort: 31010
        - containerPort: 9047
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        emptyDir: {}
"""

pipeline {
  agent {
      kubernetes {
          yaml kubeAgent
      }
  }
  // parameters {
  //     string(name: 'JENKINS_BUILD_NAME', defaultValue: '', description: '''The Name of the build we're building images for e.g: cloud/DC-151, master or pull-requests''')
  //     string(name: 'JENKINS_BUILD_NUMBER', defaultValue: '', description: '''The Number of the job we're building images for e.g: 1950(master), 2(cloud-DC or PR)''')
  //     string(name: 'DREMIO_PR_NUM', defaultValue: '', description: '''Only applies to pull request builds. ID number from the GitHub PR e.g: 177''')
  //     booleanParam(name: 'update_params', defaultValue: 'false', description: '''Only update parameters for the pipeline (declarative pipelines require this...)''')
  // }
  environment {
    RETRY_COUNT = 12
    SLEEP_INTERVAL = 5
    MINIO_HEALTH_URL = 'http://localhost:9000/minio/health/live'
    DREMIO_HEALTH_URL = 'http://localhost:9047'
    MINIO_ROOT_USER = 'admin'
    MINIO_ROOT_PASSWORD = 'password'
    DREMIO_SOFTWARE_USERNAME = 'dremio'
    DREMIO_SOFTWARE_PASSWORD = 'dremio123'
    DREMIO_SOFTWARE_HOST = 'localhost'
    DREMIO_DATALAKE = 'dbt_test_source'
    DREMIO_DATABASE = 'dbt_test'
    DBT_TEST_USER_1 = 'dbt_test_user_1'
    DBT_TEST_USER_2 = 'dbt_test_user_2'
    DBT_TEST_USER_3 = 'dbt_test_user_3'
  }

  stages {
    stage('Checkout') {
        steps {
            checkout scm  // Repo A (default checkout)

            dir('dremio') {  // Checkout Repo B in a separate folder
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/master']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/dremio/dremio.git',
                        credentialsId: 'github-dremio-jenkins-app'
                    ]]
                ])
            }
        }
    }

    stage('Check Container Status') {
      steps {
        script {
          def podName = sh(script: "kubectl get pods -l app=dbt-dremio-testing -o jsonpath='{.items[0].metadata.name}'", returnStdout: true).trim()
          
          def minioStatus = sh(script: "kubectl get pod ${podName} -o jsonpath='{.status.containerStatuses[?(@.name==\"minio\")].state}'", returnStdout: true).trim()
          if (!minioStatus.contains('running')) {
            error "MinIO container is not running. Current status: ${minioStatus}"
          }
          
          def dremioStatus = sh(script: "kubectl get pod ${podName} -o jsonpath='{.status.containerStatuses[?(@.name==\"dremio\")].state}'", returnStdout: true).trim()
          if (!dremioStatus.contains('running')) {
            error "Dremio container is not running. Current status: ${dremioStatus}"
          }
        }
      }
    }

    stage('Install MinIO Client (mc)') {
      steps {
        sh 'bash .github/scripts/install_minio_client.sh'
      }
    }

    stage('Create MinIO bucket') {
      steps {
        sh 'bash .github/scripts/create_minio_bucket.sh'
      }
    }

    stage('Create and Format Sources') {
      steps {
        sh 'bash .github/scripts/create_and_format_sources.sh'
      }
    }
  }
}
