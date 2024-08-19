#!/bin/bash

DAGS_PATH=$1
SLEEP_TIME=$2

if [[ -z "$DAGS_PATH" ]]; then
    echo "Error: DAGS_PATH is not set"
    exit 1
fi

echo "Sleeping for ${SLEEP_TIME}s"
sleep "${SLEEP_TIME}"

echo "Creating the copy-dags-pod..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: copy-dags-pod
  namespace: airflow
spec:
  containers:
  - name: copy-dags-container
    image: busybox
    command: ["/bin/sh", "-c", "sleep 3600"]
    volumeMounts:
    - name: airflow-dags
      mountPath: /mnt/dags
  volumes:
  - name: airflow-dags
    persistentVolumeClaim:
      claimName: airflow-dags
  restartPolicy: Never
EOF

echo "Waiting for copy-dags-pod to be ready..."
kubectl wait --for=condition=Ready pod/copy-dags-pod --namespace airflow --timeout=60s

if [[ $? -ne 0 ]]; then
    echo "Error: copy-dags-pod is not ready. Exiting."
    kubectl delete pod copy-dags-pod --namespace airflow
    exit 1
fi

for dag_file in "${DAGS_PATH}"/*; do
    if [[ -f "$dag_file" ]]; then
        echo "COPYING DAG: ${dag_file}"
        kubectl cp "${dag_file}" airflow/copy-dags-pod:/mnt/dags/

        if [[ $? -ne 0 ]]; then
            echo "Error copying DAG: ${dag_file}"
            kubectl delete pod copy-dags-pod --namespace airflow
            exit 1
        fi
    fi
done

kubectl delete pod copy-dags-pod --namespace airflow

echo "All DAGs copied successfully!"
