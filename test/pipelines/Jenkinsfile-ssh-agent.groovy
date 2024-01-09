/**
 * Request was, if an pipeline using an SSH Agent gets reconnected to the next replica when the active replica fails
 */
pipeline {
    agent {
        /**
         * This label reference an SSH agent
         */
        label "ssh-agent"
    }
    triggers {
        cron '* * * * *'
    }

    stages {
        stage('Hello') {
            steps {
                echo 'Hello World'
                sh "hostname"
            }
        }
    }
}
