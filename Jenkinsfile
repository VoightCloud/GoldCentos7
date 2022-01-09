import java.time.*
import java.time.format.DateTimeFormatter

def now = LocalDateTime.now()

def branch = env.BRANCH_NAME.replaceAll("/", "-")
def IP_ADDR
def INSTANCE_ID
def scanresultid
def instanceName = now.format(DateTimeFormatter.ofPattern("yyyy.MM.dd")) + "-" + env.BUILD_NUMBER
currentBuild.displayName = instanceName
def fullscap = false
def IS_MAIN = (env.BRANCH_NAME == 'master' || env.BRANCH_NAME == 'main' || env.BRANCH_NAME.startsWith('PR-'))
def build_number = (env.BRANCH_NAME == 'master' || env.BRANCH_NAME == 'main' ? env.BUILD_NUMBER.padLeft(3, '0') : env.BUILD_NUMBER.padLeft(3, '0') + UUID.randomUUID().toString()[-3..-1])
def INSTANCE_ENVIRONMENT_TAG
def INSTANCE_IC_PLATFORM_TAG
def BASE_AMI
def reportName
def liteReportName

podTemplate(label: "build",
        containers: [containerTemplate(name: 'packer-terraform',
                image: 'voight/packer-terraform:1.2',
                alwaysPullImage: false,
                ttyEnabled: true,
                privileged: true,
                command: 'cat'),
                     containerTemplate(name: 'jnlp', image: 'jenkins/inbound-agent:latest-jdk11', args: '${computer.jnlpmac} ${computer.name}')]) {
    node('build') {
        ansiColor('xterm') {
            stage('Build') {
                withCredentials([sshUserPrivateKey(credentialsId: 'cloud_init_vm_prv_key', keyFileVariable: 'cloud_init_vm_prv_key')]) {
                    withCredentials([string(credentialsId: 'cloud_init_vm_pub_key', variable: 'cloud_init_vm_pub_key')]) {
                        withCredentials([usernamePassword(credentialsId: 'proxmox_token', passwordVariable: 'PM_API_TOKEN_SECRET', usernameVariable: 'PM_API_TOKEN_ID')]) {

                            container('packer-terraform') {
                                def scmVars = checkout([$class           : 'GitSCM',
                                                        userRemoteConfigs: scm.userRemoteConfigs,
                                                        branches         : scm.branches,
                                                        extensions       : scm.extensions])

//                            try {
                                dir('template-ec2') {
                                    script {
                                        echo "Build the Environment"
                                        def varMap = [:]
                                        varMap["fullscap"] = fullscap
                                        varMap["build_number"] = build_number
                                        varMap["ssh_public_key"] = "'${cloud_init_vm_pub_key}'"

                                        sh "terraform --version"
                                        sh "terraform init"

                                        sh "terraform workspace new ${branch} || true"
                                        sh "terraform workspace select ${branch}"

                                        //def terraformStringBuilder
                                        def varString = terraformVarStringBuilder(varMap)

                                        sh "cp ${cloud_init_vm_prv_key} ./ssh-key.pem"

                                        sh "chmod 0600 ./ssh-key.pem"

                                        sh "terraform plan -no-color ${varString}"
                                        sh "terraform apply -auto-approve  ${varString}"

                                        IP_ADDR = getOutput("ip | sed s/\\\"//g")
//                                        INSTANCE_ID = getOutput("gold-ami_id")
//                                        BASE_AMI = getOutput("base_ami")
                                    }
                                }
                                def pemJSON = getPEMjson(cloud_init_vm_prv_key, "aws_certificate", "pem.json")

                                def ansibleVarMap = [:]
                                localDeploy("./playbook.yaml", ansibleVarMap, pemJSON, IP_ADDR)

                                sh "terraform destroy -auto-approve"

                                sh "rm -f ./ssh-key"

//                                sh "curl -k -s -X DELETE https://192.168.137.7:8006/api2/json/nodes/ugli/storage/local/content/local:iso/${ksisoname} -H 'Authorization: PVEAPIToken=$packer_username=$packer_token'"
                            }
//                            } finally {
//                                // Delete the temporary VM
//                                // This is probably at the end and handled after template snapshot.
//                                sh "curl -k -s -X DELETE https://192.168.137.7:8006/api2/json/nodes/ugli/storage/local/content/local:iso/${ksisoname} -H 'Authorization: PVEAPIToken=$packer_username=$packer_token'"
//                            }
                        }
//                            }
                    }
                }
            }
//                    stage('Provision with Ansible Tower') {
//                        when {
//                            expression { 'true' == 'true' }
//                        }
//                        steps {
//                            vault(vaultConfig, secrets) {
//                                script {
//                                    vault(vaultConfig, secrets) {
//                                        jobId = tower.deploy("${ansible_zsuser}", "${ansible_zspassword}", ANSIBLE_TOWER_URL, ANSIBLE_TEMPLATE_NAME, IP_ADDR, INSTANCE_ID, INSTANCE_IC_PLATFORM_TAG, INSTANCE_ENVIRONMENT_TAG, env.BRANCH_NAME)
//                                        utilities.makePem(aws_certificate, "./ssh-key.pem")
//
//                                        // Capture SCAP Reports
////                            sh "scp -i ./ssh-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null zzadmin@${IP_ADDR}:/tmp/*.html ."
////                            sh "rm ./ssh-key.pem"
//
//                                        // Archive Reports
//                                        //archiveArtifacts artifacts: '*.html'
//                                    }
//                                }
//                            }
//                        }
//                    }
//
//                    stage('Download Reports and Archive') {
//                        when {
//                            expression { IS_MAIN }
//                        }
//                        steps {
//                            script {
//                                //Archive Nessus Reports
//                                archiveArtifacts artifacts: "${reportName}.pdf, ${liteReportName}.pdf"
//                            }
//                        }
//                    }
//
//                    stage('Unregister with Ansible Tower') {
//                        when {
//                            expression { 'true' == 'true' }
//                        }
//                        steps {
//                            vault(vaultConfig, secrets) {
//                                script {
//                                    tower.deploy("${ansible_zsuser}", "${ansible_zspassword}", ANSIBLE_TOWER_URL, UNREGISTER_TEMPLATE, IP_ADDR, INSTANCE_ID, INSTANCE_IC_PLATFORM_TAG, INSTANCE_ENVIRONMENT_TAG, "main")
//                                }
//                            }
//                        }
//                    }
//
//                    stage('Shutdown the Instance') {
//                        when {
//                            expression { 'true' == 'true' }
//                        }
//                        withCredentials([sshUserPrivateKey(credentialsId: 'cloud_init_vm_prv_key', keyFileVariable: 'cloud_init_vm_prv_key')]) {
//                            withCredentials([string(credentialsId: 'cloud_init_vm_pub_key', variable: 'cloud_init_vm_pub_key')]) {
//                                withCredentials([usernamePassword(credentialsId: 'proxmox_token', passwordVariable: 'PM_API_TOKEN_SECRET', usernameVariable: 'PM_API_TOKEN_ID')]) {
//                                    script {
//                                        def varMap = [:]
//                                        varMap["fullscap"] = fullscap
//                                        varMap["build_number"] = build_number
//                                        varMap["ssh_public_key"] = "'${cloud_init_vm_pub_key}'"
//
//                                        sh "terraform workspace new ${branch} || true"
//                                        sh "terraform workspace select ${branch}"
//
//                                        //def terraformStringBuilder
//                                        def varString = terraformVarStringBuilder(varMap)
//
//
//                                        sh "terraform refresh"
//                                        sh "terraform destroy -auto-approve  ${varString}"
//                                    }
//                                }
//                            }
//                        }
//
//                    stage('Snapshot the Instance') {
//                        when {
//                            expression { 'true' == 'true' }
//                        }
//                        steps {
//                            script {
//                                AMI_ID = terraform.snapshotInstance(branch, "Cent7", instanceName, INSTANCE_ID)
////                    terraform.tagImage(AMI_ID, BASE_AMI)
////                    if (branch == "master" || branch == 'main' ) {
////                        terraform.addUserLaunchPermission(AMI_ID, users)
////                    }
//                            }
//                        }
//                    }
        }
    }
}


def getOutput(tag) {
    def retVal
    retVal = sh(
            script: "terraform output ${tag}",
            returnStdout: true
    ).trim()

    return retVal
}

def terraformVarStringBuilder(varMap) {
    def varString = ""
    for (def key in varMap.keySet()) {
        println "key = ${key}, value = ${varMap[key]}"
        varString += " -var ${key}=${varMap[key]}"
    }
    return varString
}

def localDeploy(playbook, varMap, varFileName, IP_ADDR){
    // Make backup before sed command

//    sh "cp ./roles/requirements.yml ./roles/requirements.yml.bak"
//    // SED to add git token to requirements
//    sedCommand = "sed -i 's|https://github|https://${gitToken}@github|g' ./roles/requirements.yml"
//    sedResult = sh(returnStdout: true, script: "${sedCommand}")

    sedCommand = "sed -i 's/IP_ADDR/${IP_ADDR}/g' hosts.yaml"
    sedResult = sh(returnStdout: true, script: "${sedCommand}")

    // Generate ansible vars extra parameters
    if(varFileName != null) {
        varsString = ansibleVarStringBuilder(varMap, varFileName)
    } else {
        varsString = ansibleVarStringBuilder(varMap)
    }

    // Pull down dependencies
    sh "ansible-galaxy install -r ./roles/requirements.yml -p roles/"

    // Call Ansible-playbook
    sh "ansible-playbook ${varsString} ${playbook}"

    // Remove requirements with embedded git token
    sh "rm ./roles/requirements.yml"

    sh "rm ./ssh-key.pem"

    // Move backup file back in case somebody needs to troubleshoot the workspace
    sh "mv ./roles/requirements.yml.bak ./roles/requirements.yml"
}

//def localDeploy(gitToken, aws_certificate, playbook, varMap, varFileName, repo_url, repo_branch, IP_ADDR, INSTANCE_ENVIRONMENT_TAG){
//    // Clone repo + branch
//    dir("repo"){
//        // Inject token into git repo
//        authRepo = sh(returnStdout: true, script: "sh -c \"echo -n ${repo_url} | sed 's|https://github|https://${gitToken}@github|g'\"")
//
//        // Clone the repo
//        sh "git clone -b ${repo_branch} ${authRepo} ."
//
//        // Call the deployment
//        localDeploy(gitToken, aws_certificate, playbook, varMap, varFileName, IP_ADDR, INSTANCE_ENVIRONMENT_TAG)
//    }
//}

def ansibleVarStringBuilder(varMap, varFileName){
    return ansibleVarStringBuilder(varMap) + " -e ${varFileName}"
}

def ansibleVarStringBuilder(varMap){
    def varString = ""
    for (def key in varMap.keySet()) {
        println "key = ${key}, value = ${varMap[key]}"
        varString += " -e ${key}=\"${varMap[key]}\""
    }
    return varString
}

def getPEMjson(certString, certName, fileName){
    pemJSON = "{\"${certName}\":\"${certString}\"}"
    sh "#!/bin/sh -e\necho '${pemJSON}' > ${fileName}"
    sh "chmod 0600 ${fileName}"
    return "${fileName}"
}


