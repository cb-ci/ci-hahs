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


                //This requires script approvals
                /*
                    method java.net.InetAddress getCanonicalHostName
                    staticMethod java.net.InetAddress getLocalHost
                 */
                script {
                    println("Running on Controller Host : " + InetAddress.localHost.canonicalHostName)
                }
                echo '''
                    YOU CAN RUN NOW FOR TESTING:
                    kubectl delete pod <ACTIVE_REPLICA_POD>
                    
                    YOU CAN WATCH THE REPLICA DETAILS:
                    kubectl get rs
                    kubectl get deployment
                    kubectl top pods
                                        
                    THEN WATCH THE PIPELINE LOG TO VERIFY THE AGENT WAS RECONNECTED TO THE OTHER REPLICA     
                '''

                sh '''
                    set +x
                    while true
                    do
                    	printf '%s %s\n' "$(date) Running on Agent-Pod: $(hostname)"
                    	sleep 2
                    done
                '''
            }
        }
    }
}
