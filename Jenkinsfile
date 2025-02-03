pipeline {
  agent { label 'ubuntu' }

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
        checkout scm
      }
    }

    stage('Create Docker Network') {
      steps {
        sh 'docker network create ci-network || echo "Network already exists"'
      }
    }

    stage('Start MinIO Service') {
      steps {
        sh 'bash .github/scripts/start_minio.sh'
      }
    }

    stage('Start Dremio Service') {
      steps {
        sh 'bash .github/scripts/start_dremio.sh'
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
