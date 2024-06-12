pipeline {
    agent any
    environment {
        TF_IN_AUTOMATION = 'true'
        TF_CLI_CONFIG_FILE = credentials('tf-cred')
        AWS_SHARED_CREDENTIALS_FILE='/home/ubuntu/.aws/credentials'
    }
    stages {
        stage('Init') {
            steps {
                sh 'ls'
                sh 'cat $BRANCH_NAME.tfvars'
                sh 'terraform init -no-color'
            }
        }
        stage('Plan') {
            steps {
                sh 'terraform plan -no-color -var-file="$BRANCH_NAME.tfvars"'
            }
        }
        stage('Validate Apply') {
            when {
                beforeInput true
                branch "dev"
            }
            input {
                message "Do you want to Apply this plan?"
                ok "Apply"
            }
            steps {
                echo 'Apply Accepted'
            }
        }
        stage('Apply') {
            steps {
                sh 'terraform apply -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
            }
        }
        stage('Inventory') {
          steps {
                sh '''printf \\
                    "\\n$(terraform output -json instance_ips | jq -r \'.[]\')" \\
                    >> aws_hosts'''
            }
        }
        stage('Ec2 Wait') {
            steps {
                sh '''aws ec2 wait instance-status-ok \\
                    --instance-ids $(terraform show -json | jq -r \'.values\'.\'root_module\'.\'resources[] | select(.type == "aws_instance").values.id\') \\
                    --region us-east-1'''
            }
        }
        stage('Validate Ansible') {
            when {
                beforeInput true
                branch "dev"
            }
            input {
                message "Do you want to run Ansible?"
                ok "Run Ansible"
            }
            steps {
                echo 'Ansible Approved'
            }
        }
        stage('Ansible') {
            steps {
                ansiblePlaybook(credentialsId: 'ec2-ssh-key', inventory: 'aws_hosts', playbook: 'playbooks/main-playbook.yml')
            }
        }
        stage('Test installed applcations') {
            steps {
                ansiblePlaybook(credentialsId: 'ec2-ssh-key', inventory: 'aws_hosts', playbook: 'playbooks/app-test.yml')
            }
        }
        stage('Validate Destroy') {
            input {
                message "Do you want to destroy?"
                ok "Destroy"
            }
            steps {
                echo 'Destroy Approved'
            }
        }
        stage('Destroy') {
            steps {
                sh 'terraform destroy -auto-approve -no-color'
            }
        }
    }
    post {
        success {
            echo 'succeeded!'
        }
        failure {
            echo 'Destroying the infrastructure'
            sh 'terraform destroy -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
        }
        aborted {
            echo 'Destroying infrastructure as aborted'
            sh 'terraform destroy -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
        }
    }
}
