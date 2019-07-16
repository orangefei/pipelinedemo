
����jenkins pipelineʵ���Զ�������������k8s
�ο���https://www.jianshu.com/p/2d89fd1b4403

���ճ������У��������з��������󣬶��Ҿ������������ֻ��������磺dev��test��pro��
��Ȼ����ʹ���ֶ��������ϴ�����������ķ�ʽ������΢����ܹ���һ����Ŀ�����������΢����Ĳ���������ֶ���ʽ�ͻ�ǳ������������׳���ʹ��jenkins���SCM����ʵ�ִ���������Զ�������������̡�
�������Զ�����������̴�����������²��裺

1.�ύspring boot��Ŀ���벢����git tag���ϴ����뼰tag��gitlab
2.gitlabͨ��webhook�Զ�����jenkinsִ������
3.jenkins��ȡ���룬ִ�д�����롢����docker�����ϴ�docker������harbor����ֿ⡢ִ��kubectl�������k8s��

�����в���jenkins pipelineִ������jenkins�Ĺ������̣���pipeline��ʹ��dockerִ��maven���������й�����docker�����tagֱ�Ӳ���git�е�tag��
�����ʾ���У�jenkins�汾Ϊ2.121.3��gitlab�汾Ϊ10.0.2-ce�����ʹ�õİ汾��һ�¿��ܻ��в������ò��졣

����ֻ��ʾ�ֶ�������Ϊ������һ�������в������������Ե��������
һ������jenkins
rpm yum 
war������ java -jar jenkins.war --ajp13Port=-1 --httpPort=8081
����׼��javaʾ������
1.ͨ�� https://start.spring.io/ ����spring boot�������̣����һ��ʾ��Controller�ࡣ
2.�޸�application�����ļ������ö˿ڡ�
3.�������У����� http://localhost:40080 ��ַ���Կ���ʾ�����н����
����ʾ����
https://github.com/orangefei/pipelinedemo.git

�������Dockerfile
�ڹ��̸�Ŀ¼����Dockerfile����������docker��������${JAR_FILE}������pipelineִ��docker buildʱ��ͨ��build-arg�������롣
FROM openjdk:8-jdk-alpine

#��������
ARG JAR_FILE
ARG WORK_PATH="/opt/demo"
# ��������
ENV JAVA_OPTS="" \
    JAR_FILE=${JAR_FILE}

#����ʱ��
RUN echo "http://mirrors.aliyun.com/alpine/v3.4/main/" > /etc/apk/repositories \
    && apk --no-cache add tzdata zeromq \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo '$TZ' > /etc/timezone

COPY target/$JAR_FILE $WORK_PATH/
WORKDIR $WORK_PATH
ENTRYPOINT exec java $JAVA_OPTS -jar $JAR_FILE


�ġ����k8s��Deployment����
�ڹ��̸�Ŀ¼����k8s-deployment.tpl�ļ������ļ�������Ϊk8s��yaml�ļ�ģ�塣
��jenkens pipelineִ��ʱ�����Ƚ�tpl�ļ���{}���������Զ��������sed�����滻Ϊʵ�ʵ����ݡ�

apiVersion: apps/v1
kind: Deployment
metadata:
  name: {APP_NAME}-deployment
  labels:
    app: {APP_NAME}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {APP_NAME}
  template:
    metadata:
      labels:
        app: {APP_NAME}
    spec:
      containers:
      - name: {APP_NAME}
        image: {IMAGE_URL}:{IMAGE_TAG}
        ports:
        - containerPort: 40080
        env:
          - name: SPRING_PROFILES_ACTIVE
            value: {SPRING_PROFILE}
�塢���Jenkinsfile
�ڹ��̸�Ŀ¼����Jenkinsfile������ִ��jenkins pipeline����Jenkinsfile�ļ��Ĵ�������������£�

environment�б���˵����environment���ĵ�˵���μ���https://jenkins.io/zh/doc/book/pipeline/jenkinsfile/#%E5%A4%84%E7%90%86%E5%87%AD%E8%AF%81 ��
HARBOR_CREDSΪharbor����ֿ���û����룬���ݱ���Ϊjenkins�ġ�username and password�����͵�ƾ�ݣ���credentials������ƾ���л�ȡ��ʹ��ʱͨ��HARBOR_CREDS_USR��ȡ�û�����HARBOR_CREDS_PSW��ȡ���롣
K8S_CONFIGΪk8s��kubectl�����yaml�����ļ����ݣ����ݱ���Ϊjenkins�ġ�Secret Text�����͵�ƾ�ݣ���credentials������ƾ���л�ȡ�����ﱣ���yaml�����ļ�������base64�����ʽ���棬������ƾ��ʱ��Ҫ����base64���롣����base64�����ǷǱ���ģ����ֱ�ӱ���ԭ�ģ�����Jenkinsfile����Ҫȥ��base64 -d ���룩
GIT_TAG����ͨ��ִ��sh�����ȡ��ǰgit��tagֵ�����ں��湹��docker����ʱʹ��git��tag��Ϊ����ı�ǩ�������������Ҳ����Ϊ�ա�


parameters�б���˵��
HARBOR_HOST��harbor����ֿ��ַ��
DOCKER_IMAGE��docker������������harbor��Ŀ���ơ�
APP_NAME��k8s�еı�ǩ���ƣ���Ӧk8s��yamlģ���е�{APP_NAME}��
K8S_NAMESPACE��k8s�е�namespace���ƣ�ִ��kubectl����Ჿ�����������ռ䡣


stages˵����
Maven Build��ʹ��docker�ķ�ʽִ��maven���args�����н�.m2Ŀ¼ӳ�����������ִ��ʱ�ظ���Զ�˻�ȡ������stash�����н�jar�ļ������������������stageʹ�á�
Docker Build��unstash��ȡjar�ļ���ͨ��sh����ִ��docker�����¼harbor�����������ϴ������Ƴ����ؾ��񡣹�������ʱ�����ȡjar�ļ�������JAR_FILE������
Deploy��ʹ��docker�ķ�ʽִ��kubectl�����ִ��ǰ�Ƚ�K8S_CONFIG�е����ݽ���base64���ܲ���Ϊ~/.kube/config�����ļ���Ȼ��ִ��sed���k8s-deployment.tpl�ļ��С�{������}����ʽ�����滻Ϊʵ�ʵĲ���ֵ�����ִ��kubectl�������k8s��




parameters�еĲ�����pipeline����ִ��һ�κ󣬵ڶ���ִ��ʱ�����ڽ������޸Ĳ���ֵ��
�����stage����һ����һ���Զ�ִ�У������Ҫ�ֶ�ִ�п���ʹ��inputָ��ʵ�֡�

�μ���https://jenkins.io/zh/doc/book/pipeline/syntax/#input

// ��Ҫ��jenkins��Credentials����������jenkins-harbor-creds��jenkins-k8s-config����
pipeline {
    agent any
    environment {
        HARBOR_CREDS = credentials('jenkins-harbor-creds')
        K8S_CONFIG = credentials('jenkins-k8s-config')
        GIT_TAG = sh(returnStdout: true,script: 'git describe --tags --always').trim()
    }
    parameters {
        string(name: 'HARBOR_HOST', defaultValue: '172.23.101.66', description: 'harbor�ֿ��ַ')
        string(name: 'DOCKER_IMAGE', defaultValue: 'tssp/pipeline-demo', description: 'docker������')
        string(name: 'APP_NAME', defaultValue: 'pipeline-demo', description: 'k8s�б�ǩ��')
        string(name: 'K8S_NAMESPACE', defaultValue: 'demo', description: 'k8s��namespace����')
    }
    stages {
        stage('Maven Build') {
            when { expression { env.GIT_TAG != null } }
            agent {
                docker {
                    image 'maven:3-jdk-8-alpine'
                    args '-v $HOME/.m2:/root/.m2'
                }
            }
            steps {
                sh 'mvn clean package -Dfile.encoding=UTF-8 -DskipTests=true'
                stash includes: 'target/*.jar', name: 'app'
            }

        }
        stage('Docker Build') {
            when { 
                allOf {
                    expression { env.GIT_TAG != null }
                }
            }
            agent any
            steps {
                unstash 'app'
                sh "docker login -u ${HARBOR_CREDS_USR} -p ${HARBOR_CREDS_PSW} ${params.HARBOR_HOST}"
                sh "docker build --build-arg JAR_FILE=`ls target/*.jar |cut -d '/' -f2` -t ${params.HARBOR_HOST}/${params.DOCKER_IMAGE}:${GIT_TAG} ."
                sh "docker push ${params.HARBOR_HOST}/${params.DOCKER_IMAGE}:${GIT_TAG}"
                sh "docker rmi ${params.HARBOR_HOST}/${params.DOCKER_IMAGE}:${GIT_TAG}"
            }
            
        }
        stage('Deploy') {
            when { 
                allOf {
                    expression { env.GIT_TAG != null }
                }
            }
            agent {
                docker {
                    image 'lwolf/helm-kubectl-docker'
                }
            }
            steps {
                sh "mkdir -p ~/.kube"
                sh "echo ${K8S_CONFIG} | base64 -d > ~/.kube/config"
                sh "sed -e 's#{IMAGE_URL}#${params.HARBOR_HOST}/${params.DOCKER_IMAGE}#g;s#{IMAGE_TAG}#${GIT_TAG}#g;s#{APP_NAME}#${params.APP_NAME}#g;s#{SPRING_PROFILE}#k8s-test#g' k8s-deployment.tpl > k8s-deployment.yml"
                sh "kubectl apply -f k8s-deployment.yml --namespace=${params.K8S_NAMESPACE}"
            }
            
        }
        
    }
}

-----
����jenkins pipeline����
����jenkins pipeline���񣬲�������Ҫ�Ĳ�����
�½�pipeline����
������½����񡱣��������Ʋ�ѡ����ˮ�ߡ���pipeline����Ȼ����ȷ����

���� pipeline����
������������ý��棬����ˮ�ߣ�pipeline�����ò��֣�ѡ��Pipeline script from SCM����
SCMѡ��ѡΪ��Git�������úù��̵�git��ַ�Լ���ȡ�����ƾ֤��Ϣ��Ȼ���ڡ�Additional Behaviours������ӡ�Clean before checkout����

����harbor�˺�������
ѡ��ƾ�ݡ���Ȼ������ͼ��ʾλ�õ�������ƾ�ݡ���
����ƾ�����ý��棬����ѡ��Ϊ��Username with password����ID����Ϊ��jenkins-harbor-creds�����˴���ID������Jenkinsfile�еı���һ�£���
Username��Password�ֱ�����Ϊharbor����˽����û��������롣

����k8s��kube.config������Ϣ
k8s��ʹ��kubectl����ʱ��Ҫyaml��ʽ�ķ���������Ȩ��Ϣ�����ļ������ｫkubectl��yaml�����ļ���������base64����󱣴���jenkins��ƾ���С�pipeline����ִ��ʱ���ȴ�jenkinsƾ���л�ȡ���ݣ�����base64��������ñ���Ϊ~/.kube/config�ļ���kubectl�������ļ����������£�
apiVersion: v1
kind: Config
clusters:
- name: "test"
  cluster:
    server: "https://xxxxx"
    api-version: v1
    certificate-authority-data: "xxxxxx"

users:
- name: "user1"
  user:
    token: "xxxx"

contexts:
- name: "test"
  context:
    user: "user1"
    cluster: "test"

current-context: "test"

������linux�в����������kubectl��yaml�����ļ�����base64���롣
base64 kube-config.yml > kube-config.txt

Ȼ��������һ������jenkinsƾ�������������ļ����ݡ�
��ƾ�����ý��棬����ѡ��Ϊ��Secret text����ID����Ϊ��jenkins-k8s-config�����˴���ID������Jenkinsfile�еı���һ�£���Secret����Ϊ���澭��base64�����������ļ�����


����pipeline����
�ڴ�����pipeline�����У������������������������ִ��pipeline����

��jenkins�д���һ����ΪBlue Ocean���½��棬���½�����Ҳ����ִ��pipeline���񣬶����µĽ����в鿴�����ִ�н����������������ִ�н����־�������½����в鿴��
�����Open Blue Ocean���˵������½��档
��Blue Ocean�½����У����Ե�������С�ִ��pipeline����

��ִ��pipeline����ִ�С�git describe --tags���������������������ʾ����Jenkinsfile��Ҫ�������git��tag����git������tag�����ύ�ϴ���gitlab�󼴿ɽ����
��git������tag�����ύ�ϴ���gitlab������ִ��pipeline�������в��趼ִ�гɹ���
ִ�гɹ��󣬲鿴harbor����ֿ⣬docker����ɹ��ϴ���harbor��
ִ�гɹ��󣬲鿴k8s��pod������־�����������ɹ���


======
��Ҫ�Ĳ����
ϵͳ����--������--��ѡ���--����Blue Ocean pipeline 

�Ŵ�
fatal: No names found, cannot describe anything
1����ִ��pipeline����ִ�С�git describe --tags���������
git tag -a v1.4 -m "2019-0712"
git describe --tags
git push origin  v1.4
git push origin --tags ���е�tag���ύ��gitlab


2��Error from server (NotFound): error when creating "k8s-deployment.yml": namespaces "demo" not found
���������ռ�
kubectl create namespace demo

====
��Ҫ�޸�ģ������Ӧ�Լ���ʵ�ʻ���



