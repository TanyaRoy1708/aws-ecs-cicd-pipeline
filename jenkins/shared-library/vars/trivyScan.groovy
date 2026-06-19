def call(Map config = [:]) {
    def type = config.get('type', 'image')
    def target = config.get('target')
    def reportFile = config.get('reportFile', "trivy-${type}-report.txt")

    echo "Running Trivy ${type} scan on target: ${target}..."

    sh """
        trivy ${type} --exit-code 1 \
                      --ignore-unfixed \
                      --severity CRITICAL \
                      --format table \
                      --output ${reportFile} \
                      ${target}
    """
}
