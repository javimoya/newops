# newops  

## 👈 use case 1
Remarks:

 - I could have used many other tools (best suited for all of this -helm, terraform, ansible, etc-)... but just too many things to setup 😃
 - The cluster created, for the same reason, it's Public Topology. In a real scenario would be [Private Topology](https://kops.sigs.k8s.io/topology/) and maybe a [Bastion](https://kops.sigs.k8s.io/bastion/) 

### ⏩ prerequisites 

Make sure you have installed kOps, kubectl, and the gcloud tools if you want to provision everything from scratch. You'll need a Google Cloud account, and make sure that gcloud is logged in to your account.

    gcloud auth login --update-adc

(If you you haven't created an SSH key, you'll have to: ssh-keygen -t rsa)

    cd use-case-1  

#### ⏩ how to bootstrap gcp+cluster+monitoring+logging f

**(⚠️ I understand you can skip this section, this is only to bootstrap everything from scratch, fully scripted)**

Set the GCP Project Name to be created (e.g. newops99 -must be unique, non existing-):

    export PROJECT=<redacted>

Set your GCP Billing Account Id (e.g. XXXXX-XXXXX-XXXXX):

    export BILLING_ACCOUNT=<redacted>

Set your desired Kibana Password (e.g. mypass):

    export KIBANA_PASSWORD=<redacted>

Bootstrap the Cluster:

    ./bootstrap.sh $PROJECT $BILLING_ACCOUNT

Then you need to wait until the cluster it's fully provisioned (can take 15 minutes):

    ./bootstrap-wait.sh $PROJECT

Generate kubeconfig:

    ./kubeconfig.sh $PROJECT

Install Monitoring (Prometheus+Kube State Metrics+Alert Manager+Grafana+Node Exporter):

    ./monitoring.sh

Install Logging (Elasticsearch+Fluentd+Kibana):

    ./logging.sh $KIBANA_PASSWORD

Create a demo pod with kubernetes.io/gce-pd (gce persistent disk)

    ./storage-provisioner.sh


#### ⏩ how to access Prometheus+Alert Manager+Grafana+Kibana

**Ensure you are using the given kubeconfig, context, etc** 

    export KUBECONFIG=<file  absolute  path>
    kubectl config view
    etc

**Trigger everything**

    ./up.sh

**PROMETHEUS**

    In your browser: http://localhost:8080
    
    Example: http://localhost:8080/graph?g0.expr=container_cpu_usage_seconds_total&g0.tab=0&g0.stacked=0&g0.show_exemplars=0&g0.range_input=1h

**ALERT MANAGER**

    In your browser: http://localhost:8081

**GRAFANA**

    In your browser: http://localhost:8082
    
    User: admin Pass: admin. Once you log in with default credentials, it will prompt you to change the default password.

**KIBANA**

    In your browser: http://localhost:8083
    
    User: elastic Pass: mypass.
    
    Example: There is a test pod creating logs.
    
    kubectl get pods log-generator -n default
    
    On Kibana: create an index pattern logstash-*

  **Stop All**

    pgrep kubectl | xargs kill -9

  

#### ⏩ CI/CD set-up for a simple test application

Edit the sample app https://github.com/javimoya/newops/blob/main/source/server.js

    (update "Hello World" and push into master)
  
A pipeline will run automatically and will (re)deploy the app.
Once finished:

    SAMPLE_POD=$(kubectl get pod --namespace=default -l app=sample -o jsonpath="{.items[0].metadata.name}")
    kubectl port-forward ${SAMPLE_POD} 8090:8090 -n default
    http://localhost:8090/

  

#### ⏩ storage provisioner

ssh into this pod

    kubectl get pods nginx -n default
    kubectl exec -it nginx -n default -- bash

create a file inside /var/lib/www/html

    touch /var/lib/www/html/a

ssh into second pod

    kubectl exec -it nginx2 -n default -- bash
    ls /var/lib/www/html/  

File is there.
You can also delete the pod and recreate it to validate persistence, and you can see on gcp ui the gce disk.

#### ⏩ how to clean-up everything

**(⚠️ I understand you want to skip this section)**

    ./storage-provisioner-remove.sh
    ./logging-remove.sh
    ./monitoring-remove.sh
    ./unbootstrap.sh $PROJECT

Take into account that the GCP Project is not deleted.
