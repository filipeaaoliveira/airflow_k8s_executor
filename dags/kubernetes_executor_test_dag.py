import logging
from datetime import timedelta
from typing import Optional

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.utils.dates import days_ago

default_args = {
    "owner": "airflow",
    "retries": 3,
    "retry_delay": timedelta(minutes=10),
    "depends_on_past": False,
}

logging.basicConfig(level=logging.INFO)


def start_task(**kwargs) -> None:
    """
    Initial task that marks the start of the DAG.

    Args:
        **kwargs: Any keyword arguments passed by Airflow.

    Returns:
        None
    """
    logging.info("Start Task: DAG has started successfully.")


def process_data(data: Optional[str], **kwargs) -> str:
    """
    A simulated data processing task that takes input data and processes it.

    Args:
        data: An optional string to process.
        **kwargs: Any keyword arguments passed by Airflow.

    Returns:
        str: The processed data result.
    """
    if not data:
        data = "default_data"

    logging.info(f"Processing data: {data}")

    processed_data = data.upper()

    logging.info(f"Data processed successfully: {processed_data}")

    return processed_data


def end_task(**kwargs) -> None:
    """
    Final task that marks the end of the DAG.

    Args:
        **kwargs: Any keyword arguments passed by Airflow.

    Returns:
        None
    """
    logging.info("End Task: DAG has completed successfully.")


with DAG(
    dag_id="kubernetes_executor_test_dag",
    description="A comprehensive DAG to test Kubernetes Executor",
    default_args=default_args,
    schedule_interval=None,
    start_date=days_ago(1),
    catchup=False,
    tags=["kubernetes", "executor", "test"],
) as dag:
    start = PythonOperator(
        task_id="start_task",
        python_callable=start_task,
        retries=2,
        retry_delay=timedelta(minutes=5),
    )

    process = PythonOperator(
        task_id="process_data_task",
        python_callable=process_data,
        op_kwargs={"data": "sample_data"},
    )

    end = PythonOperator(
        task_id="end_task",
        python_callable=end_task,
    )

    start >> process >> end
