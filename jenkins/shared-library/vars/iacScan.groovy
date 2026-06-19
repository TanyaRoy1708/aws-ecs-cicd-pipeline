def call(Map config = [:]) {
    def softFail = config.get('softFail', true)
    def directory = config.get('directory', 'terraform')
    
    echo "Running Checkov IaC Scan on directory: ${directory}"
    
    def softFailFlag = softFail ? "--soft-fail" : ""
    
    sh """
        checkov -d ${directory} \
          --framework terraform \
          --output cli \
          ${softFailFlag}
    """
}
