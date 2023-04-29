# newops

## use case 1



### prerequisites

Make sure you have installed kOps and installed kubectl, and installed the gcloud tools.

You'll need a Google Cloud account, and make sure that gcloud is logged in to your account.

gcloud auth login --update-adc

(If you haven't created an SSH key, you'll have to: ssh-keygen -t rsa)

cd use-case-1

#### how to bootstrap gcp+cluster+monitoring+logging

(I guess you can skip this section, this is only to bootstrap everything from scratch)

Set the GCP Project Name to be created (e.g. newops99 -must be unique, non existing-):
export PROJECT=<redacted>

Set your GCP Billing Account Id (e.g. XXXXX-XXXXX-XXXXX): 
export BILLING_ACCOUNT=<redacted>

Set your Kibana Password (e.g. mypass):
export KIBANA_PASSWORD=<redacted>

Bootstrap the Cluster:
./bootstrap.sh $PROJECT $BILLING_ACCOUNT

Wait until the cluster it's fully provisioned (can take 15 minutes):
./bootstrap-wait.sh $PROJECT

Get kubeconfig:
./kubeconfig.sh $PROJECT

Install Monitoring (Prometheus+Kube State Metrics+Alert Manager+Grafana+Node Exporter):
./monitoring.sh

Install Logging (Elasticsearch+Fluentd+Kibana):
./logging.sh $KIBANA_PASSWORD

#### how to access Prometheus+Alert Manager+Grafana+Kibana

1) Ensure you are using the given kubeconfig, context, etc (export KUBECONFIG=<file absolute path>, kubectl config view, etc)

2) ./up.sh

3) 
PROMETHEUS
In your browser: http://localhost:8080
Example: http://localhost:8080/graph?g0.expr=container_cpu_usage_seconds_total&g0.tab=0&g0.stacked=0&g0.show_exemplars=0&g0.range_input=1h

ALERT MANAGER
In your browser: http://localhost:8081

GRAFANA
In your browser: http://localhost:8082
User: admin Pass: admin. Once you log in with default credentials, it will prompt you to change the default password.

KIBANA
In your browser: http://localhost:8083
User: elastic Pass: mypass.
Example: There is a test pod creating logs.
kubectl get pods log-generator -n default
On Kibana: create an index pattern logstash-*

3) Stop all: pgrep kubectl | xargs kill -9

#### CI/CD set-up for a simple test application

1) Edit the app https://github.com/javimoya/newops/blob/main/source/server.js
(update "Hello World" and push into master)

2) A pipeline will run automatically and will (re)deploy the app

3) Once finished
SAMPLE_POD=$(kubectl get pod --namespace=default -l app=sample -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward ${SAMPLE_POD} 8090:8090 -n default
http://localhost:8090/

#### how to clean-up everything

(I guess you want to skip this section)

./logging-remove.sh
./monitoring-remove.sh
./unbootstrap.sh $PROJECT

Take into account that the GCP Project is not deleted.

--topology private --bastion

<!-- kops export kubeconfig --admin -->

kops validate cluster --wait 10m
kops delete cluster --name ${NAME} --yes

unboostrap.sh

source ./unbootstrap.sh newops11 