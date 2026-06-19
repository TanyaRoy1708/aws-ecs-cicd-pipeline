def call(Map config = [:]) {
    def projectKey = config.get('projectKey', 'devops-toolbox')
    def sources = config.get('sources', 'app')
    
    echo "Running SonarQube Scanner against ${sources}..."
    withSonarQubeEnv('SonarQube') {
        sh """
            sonar-scanner \
              -Dsonar.projectKey=${projectKey} \
              -Dsonar.sources=${sources} \
              -Dsonar.python.version=3.11 \
              -Dsonar.host.url=\${SONAR_HOST_URL} \
              -Dsonar.token=\${SONAR_AUTH_TOKEN}
        """
    }
    
    echo "Waiting for SonarQube Quality Gate status..."
    timeout(time: 5, unit: 'MINUTES') {
        waitForQualityGate abortPipeline: true
    }
}
