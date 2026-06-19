def call(Map config = [:]) {
    def directory = config.get('directory', 'terraform')
    echo "Running Terraform validation..."
    
    dir(directory) {
        sh 'terraform fmt -check -recursive'
        sh 'terraform init -backend=false'
        sh 'terraform validate'
    }
}
