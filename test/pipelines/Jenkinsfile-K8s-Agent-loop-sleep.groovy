pipeline {
    agent {
        kubernetes {
            yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: shell
                    image: ubuntu
                    command:
                    - sleep
                    args:
                    - infinity
                '''
            defaultContainer 'shell'
        }
    }
    stages {
        stage('Main') {
            steps {
                //sleep time: 1, unit: 'HOURS'
                //input id: 'Input', message: 'abort', ok: 'continue'
                sh '''
                    while true
                    do
                     	echo "#######################################"
                    	echo "Running on Agent-Pod: $(hostname)"
                    	printf '%s %s\n' "$(date)"
                    	sleep 2
                    done
                '''
            }
        }
    }
}
