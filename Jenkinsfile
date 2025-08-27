pipeline {
  agent any
  options { timestamps() }

  parameters {
    string(name: 'PLAYBOOK', defaultValue: 'playbooks/site.yml', description: 'Playbook path')
    string(name: 'SSH_CRED', defaultValue: 'ansible-ssh-key', description: 'SSH credential ID')
  }

  environment {
    INV_FILE = "inventory/dev.ini"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Prep Ansible') {
      steps {
        sh '''
          set -eux
          python3 -m venv .venv || true
          . .venv/bin/activate
          pip install --upgrade pip
          pip install ansible boto3 botocore
        '''
      }
    }

    stage('Run Ansible') {
      steps {
        sshagent(credentials: [params.SSH_CRED]) {
          sh """
            set -eux
            . .venv/bin/activate
            ansible-inventory -i "${env.INV_FILE}" --graph
            ansible-playbook -i "${env.INV_FILE}" ${params.PLAYBOOK} -vv
          """
        }
      }
    }
  }
}
