def call(Map config = [:]) {
    echo "Running Gitleaks Secret Scan..."
    def cmd = 'gitleaks detect --source=. --verbose --redact'
    sh config.get('softFail', false) ? "${cmd} || true" : cmd
}
