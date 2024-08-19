# Airflow in Kubernetes Executor
If you want to play with Airflow + K8S executor, setting up your local system to start playing with an example takes a lot of time.
This repo aims to solve that. With this repo you can install Airflow with K8S executor this repo provides 
a base template DAG which you can edit and use to your need.    

# How it works
- When installing this setup will run a local registry for docker images so that minikube can pull the docker images from your local machine.
- Once the setup is up and running all you have to do is build the image locally and tag them as described below
    ```bash
      docker build -t myapp .
      
      # Syntax => docker tag ${APP_NAME} localhost:5000/${APP_NAME}:${LABEL}
      # example 
      docker tag myapp localhost:5000/myapp:1
    ``` 

### Pre-requisite
- Download Docker Desktop from [here](https://www.docker.com/products/docker-desktop] and setup in your local machine)
- Install Minikube, Helm & add package repo
    ```bash
          brew update
  
          # install minikube
          brew install minikube
          
          # install helm
          brew install helm
          
          # add package repository to helm 
          helm repo add stable https://charts.helm.sh/stable
    ``` 

## How do I Build ?

```bash
# ALL .PY Files in dags/ folder will be loaded as DAGS

$ make run 
# yup! that's it 
# the command takes few minutes to start, so trust the process & wait.

#Once the Make command is done execute the following commnds in different terminals
$ kubectl get pods --watch # to monitor the pod health
$ minikube dashboard  # to get the K8S dashboard

# If this URL doesn't load wait for few mins until the K8S dashboard becomes healthy. (usually takes 6-10 minutes)
$ minikube service airflow-web -n airflow # to load the Airflow UI page 

# Once you are done with the services you can stop all the services using following command 
$ make cleanup

# Commands that might be of interest during development
$ make run # -> starts everything from ground up
$ make restart # -> delete the charts & cluster and starts everything from ground up again!
$ make redeploy # -> delete the charts & re-install helm (airflow) chart again
$ make dags # -> Copy the latest DAGS from local machine to airflow
