.PHONY: build-image build-helm
.ONESHELL:


export BASE_PATH ?= $(shell pwd)
export BASH ?= $(BASE_PATH)/bash_scripts
export AIRFLOW_DAGS_PATH ?= $(BASE_PATH)/dags/


build:
	minikube start --driver=docker --memory=6096 --disk-size=20000mb --kubernetes-version v1.30.0
	@eval $$(minikube docker-env) ;\
	kubectl config set-context minikube --cluster=minikube --namespace=airflow; \
	kubectl delete namespace airflow || true ; \
	kubectl create namespace airflow; \
	kubectl apply -f pvc.yaml

deploy:
	@eval $$(minikube docker-env) ; \
	helm delete airflow || true ; \
	helm repo add apache-airflow https://airflow.apache.org ; \
	helm repo update ; \
	helm upgrade --install airflow apache-airflow/airflow \
		--namespace airflow \
		--create-namespace \
		--set executor=KubernetesExecutor \
		--set airflow.dags.persistence.enabled=true \
		--set airflow.dags.persistence.existingClaim=airflow-dags \
		--set airflow.dags.persistence.mountPath=/opt/airflow/dags \
		--set scheduler.extraVolumes[0].name=airflow-dags \
		--set scheduler.extraVolumes[0].persistentVolumeClaim.claimName=airflow-dags \
		--set scheduler.extraVolumeMounts[0].name=airflow-dags \
		--set scheduler.extraVolumeMounts[0].mountPath=/opt/airflow/dags \
		--set webserver.extraVolumes[0].name=airflow-dags \
		--set webserver.extraVolumes[0].persistentVolumeClaim.claimName=airflow-dags \
		--set webserver.extraVolumeMounts[0].name=airflow-dags \
		--set webserver.extraVolumeMounts[0].mountPath=/opt/airflow/dags \
		--set triggerer.extraVolumes[0].name=airflow-dags \
		--set triggerer.extraVolumes[0].persistentVolumeClaim.claimName=airflow-dags \
		--set triggerer.extraVolumeMounts[0].name=airflow-dags \
		--set triggerer.extraVolumeMounts[0].mountPath=/opt/airflow/dags \
		--set workers.extraVolumes[0].name=airflow-dags \
		--set workers.extraVolumes[0].persistentVolumeClaim.claimName=airflow-dags \
		--set workers.extraVolumeMounts[0].name=airflow-dags \
		--set workers.extraVolumeMounts[0].mountPath=/opt/airflow/dags \
		--set serviceAccount.create=true; \
	bash $(BASH)/load_dags.sh $(AIRFLOW_DAGS_PATH) 30




run:
	make build
	make deploy

restart:
	make cleanup
	make run

redeploy:
	helm delete airflow || true
	make deploy

cleanup:
	@eval $$(minikube docker-env) ; \
	bash $(BASH)/clean_registry.sh
	helm delete airflow || true
	minikube delete

copy-dags:
	bash $(BASH)/load_dags.sh $(AIRFLOW_DAGS_PATH) 1