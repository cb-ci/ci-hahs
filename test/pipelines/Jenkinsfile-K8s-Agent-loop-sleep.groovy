/*
The following line of Groovy get the controller replica hostname
and requires two script approvals under Manage Jenkins -> script approvals
    method java.net.InetAddress getCanonicalHostName
    staticMethod java.net.InetAddress getLocalHost
 */
def controllerHost=InetAddress.localHost.canonicalHostName
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

    options {
        //https://www.jenkins.io/doc/book/pipeline/scaling-pipeline/#what-are-the-durability-settings
        durabilityHint 'MAX_SURVIVABILITY'
        //durabilityHint 'PERFORMANCE_OPTIMIZED'
        //durabilityHint 'SURVIVABLE_NONATOMIC'
    }

    stages {
        stage('Main') {
            steps {

                /* INPUT  should never be inside an agent block,
                 however, here we could use it to block the agent
                for testing purposes
                */
                //input id: 'Input', message: 'abort', ok: 'continue'


                /*
                    Print some simple test instructions
                */
                echo """
                    THIS REPLICA RUNS ON ${controllerHost}
                    YOU CAN RUN NOW FOR TESTING:
                    kubectl delete pod ${controllerHost}
                    
                    YOU CAN WATCH THE REPLICA DETAILS:
                    kubectl get rs
                    kubectl get deployment
                    kubectl top pods
                                        
                    THEN WATCH THE PIPELINE LOG TO VERIFY THE AGENT WAS RECONNECTED TO THE OTHER REPLICA  
                """

                //sleep time: 1, unit: 'HOURS'

                /*
                We run an infinity loop with sleep to print out date and agent pod name
                */
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
