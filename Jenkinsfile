pipeline {
  agent any
  options { ansiColor('xterm'); timestamps() }

  parameters {
    choice(name: 'ENV', choices: ['dev'], description: 'Environment')
    booleanParam(name: 'CHECK_MODE', defaultValue: false, description: 'Dry-run')
    string(name: 'LIMIT', defaultValue: '', description: 'Limit hosts/groups')
    string(name: 'PLAYBOOK', defaultValue: 'playbooks/site.yml', description: 'Playbook path')
    string(name: 'SSH_CRED', defaultValue: 'ansible-ssh-key', description: 'SSH credential ID')
    string(name: 'AWS_CREDS', defaultValue: '', description: 'AWS credential ID (optional)')
    string(name: 'AWS_REGION', defaultValue: 'us-east-1', description: 'Region')
  }

  environment {
    INV_FILE = "inventory/inventory.aws_ec2.yml"   // match your repo path
  }

  stages {
    stage('Checkout') { steps { checkout scm } }

    stage('Prep Ansible') {
      steps {
        sh '''
          set -eux
          if ! command -v python3 >/dev/null 2>&1; then
            sudo apt-get update || true
            sudo apt-get install -y python3 python3-venv python3-pip || true
          fi
          python3 -m venv .venv
          . .venv/bin/activate
          pip install --upgrade pip
          pip install ansible boto3 botocore
        '''
      }
    }

    stage('Run Ansible') {
      steps {
        script {
          def run = {
            sshagent(credentials: [params.SSH_CRED]) {
              sh """
                set -eux
                . .venv/bin/activate
                ansible-inventory -i "${env.INV_FILE}" --graph
                EXTRA=""
                [ -n "${params.LIMIT}" ] && EXTRA="\${EXTRA} --limit ${params.LIMIT}"
                [ "${params.CHECK_MODE}" = "true" ] && EXTRA="\${EXTRA} --check"
                ansible-playbook -i "${env.INV_FILE}" ${params.PLAYBOOK} \${EXTRA} -vv
              """
            }
          }
          if (params.AWS_CREDS?.trim()) {
            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: params.AWS_CREDS]]) {
              withEnv(["AWS_REGION=${params.AWS_REGION}"]) { run() }
            }
          } else {
            withEnv(["AWS_REGION=${params.AWS_REGION}"]) { run() }
          }
        }
      }
    }
  }
}
