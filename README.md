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

## 👈 use case 2

Unfortunately, I haven't had enough time to make much progress on this use case. I'm only able to share this general overview of different components that could be part of such a platform.
  

### Platform Architecture Design

#### Run Platform: Google Kubernetes Engine (GKE)

Some configurations to achieve high availability and to ensure that your workloads operate properly at times of peak load:

 - Regional cluster (3 control planes) with worker nodes deployed in
   three different availability zones to achieve high availability.
   
 - Enable Cluster Autoscaler to automatically resize your nodepool size 
   based on demand.
  
 - Use Horizontal Pod Autoscaling to automatically increase or decrease 
   the number of pods based on utilization metrics.

 - Use Vertical Pod Autoscaling (VPA) in conjunction with Node Auto   
   Provisioning to allow GKE to efficiently scale your cluster both   
   horizontally (pods) and vertically (nodes).

 - If cost is not important you may want to create a large cluster and  
   use GCP reservations to guarantee any anticipated burst in resources 
   demand.

 - Make sure you set up readiness & liveness probes (and that you test  
   and validate any probes that you create).   

 - To avoid a single point of failure/less latency, use Pod
   anti-affinity/Pod affinity.

And some other configurations to enhance security:

 - In GKE the control planes are patched and upgraded for you
   automatically. Node auto-upgrade also automatically upgrades nodes in
   your cluster.
   
 - You should limit exposure of your cluster control plane and nodes to
   the internet with Public endpoint access disabled.
   
 - Consider managing Kubernetes RBAC users with Google Groups for RBAC.
 
 - Enable Shielded GKE Nodes.
  
 - Choose a hardened node image: The cos_containerd image is the
   preferred image for GKE because it has been custom built, optimized,
   and hardened specifically for running containers.
   
 - Enable Workload Identity, is the recommended way to authenticate to
   Google APIs.
   
 - Use least privilege Google service accounts. Prefer not running GKE
   clusters using the Compute Engine default service account.
   
 - Restrict traffic among Pods: Istio, k8s network policies, etc
 - 
 - Consider encrypting Kubernetes Secrets using keys managed in Cloud
   KMS. You can use Kubernetes secrets natively in GKE.

  
#### Storage

Cloud Storage could be used maybe to store patent documents and other files. Cloud Storage is a highly scalable and durable object storage solution. Can be used also for backup and data archiving.

#### Data

There are multiple options available, and to choose one or another we would need to take assumptions. Just to mention 2:

 - Cloud SQL: it's a fully managed relational database service
   that supports MySQL and PostgreSQL. It's best suited for structured
   data that requires ACID compliance. Cloud SQL is easy to set up,
   highly available, and can scale up or down as needed.
   
 - Cloud Spanner: it's a horizontally scalable, globally distributed
   relational database that provides high availability and strong
   consistency across multiple regions. It's best suited for
   mission-critical workloads that require high scalability and low
   latency. Cloud Spanner can handle both structured and semi-structured
   data.

  
#### Analyzing

BigQuery is a powerful tool for analyzing large datasets (e.g. patent data) quickly and easily.

With it powerful querying capabilities could help to extract insights from the data.

Could be integrate with Google Data Studio for visualization (patent trends, track patent application status, or monitor patent infringement activity).

BigQuery can be too a data source for machine learning models (e.g. train a model to predict future patent trends or to identify potential patent infringements)

Also could be integrated with Google Cloud Pub/Sub to stream data into BigQuery in real-time, enabling us to analyze and act on the data as it's generated.

#### AI

Cloud Natural Language API: we could extract insights from patent documents by performing entity recognition, sentiment analysis, and content classification. This could be useful for organizing and categorizing patent documents, and for identifying relevant keywords and phrases.

Cloud Vision API: could be useful for extracting data from figures and diagrams.

AutoML / Cloud AI Platform: develop models that can identify patterns in patent data or predict future patent trends, identify potential patent infringements... etc

#### Performance & Security

Google Cloud CDN can automatically cache and serve the assets from the edge locations closest to the users, reducing the latency of the requests.

Google Cloud Armor could be used to protect the platform from DDoS attacks and other malicious traffic.

Security Command Center could provide a centralized dashboard that would allow us to view the security posture of the cloud resources and identify any security issues that may arise.

We can use Google Cloud Key Management Service (KMS) to encrypt and manage the encryption keys in different GCP cloud components.

We could use Google Cloud Audit Logs to monitor and track the activity (unauthorized access or activity)

#### Monitoring & Observability

I guess the organization already have Monitoring & Observability stacks in place (Prometheus, Grafana, fluentd, Kibana, etc) but in case pure GCP solutions would be needed:

GCP Cloud Operations Suite includes several tools for:

Logging and tracing tools to collect and analyze logs and traces from the application. This can help us identify errors and performance bottlenecks in the system

Metrics and monitoring: To collect and analyze metrics from the application. This can help us monitor the performance and health of the system and identify any issues that may arise.

Alerting: We can set up alerts to notify us of any issues in the system. This can help us proactively identify and resolve issues before they impact the users.

Distributed tracing: We can use OpenTelemetry to instrument the application and collect distributed traces from the system. This can help us understand the end-to-end flow of requests.

#### Disaster Recovery: infra, app & data recovery

GCP offers different built-in tools in case of DR scenario.

Backup for GKE it's a service for backing up and restoring workloads in GKE cluster.
Backup and DR Service for centralized, application-consistent data protection.

The infrastructure could be recovered from source code if we follow a gitops model (Terraform, etc).

For data backup/recovery there are several options available (scheduled backups/snapshots, point in time recovery, etc)

#### Load Testing 

Testing tools like Apache JMeter could simulate high traffic on your platform and identify performance bottlenecks.
 
### Application Architecture Design

I understand that this it's more likely to be out of scope for a devops position, but, for sure, the architecture of the application would greatly condition the Platform Architecture.

For example, an event-driven architecture  would be much more conditional on the use of certain components (like Kafka and other async services) than for example a rest-api architecture.



  