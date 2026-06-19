def call(Map config = [:]) {
    def status = config.get('status')
    def channel = config.get('channel', '#ci-cd-alerts')
    
    if (!status) {
        error "slackNotify: 'status' parameter is required."
    }
    
    def color = (status.toUpperCase() == 'SUCCESS') ? '#36a64f' : '#ff0000'
    def message = "Pipeline *${env.JOB_NAME}* - Build *#${env.BUILD_NUMBER}* finished with status: *${status.toUpperCase()}*\nMore info at: ${env.BUILD_URL}"
    
    echo "Sending Slack notification: ${status.toUpperCase()} status to channel ${channel}..."
    slackSend(channel: channel, color: color, message: message)
}
