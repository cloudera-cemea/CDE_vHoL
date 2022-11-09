# Airflow DAG
from cloudera.cdp.airflow.operators.cde_operator import CDEJobRunOperator
from airflow.operators.bash import BashOperator
from airflow.operators.python_operator import PythonOperator
from airflow.operators.http_operator import SimpleHttpOperator
from datetime import datetime, timedelta
from dateutil import parser
from airflow import DAG
import pendulum
#from airflow.models import Variable

username = 'test_user_110822_3'

print("Running script with Username: {}", username)

default_args = {
        'owner': username,
        'retry_delay': timedelta(seconds=5),
        'depends_on_past': False,
        'start_date': pendulum.datetime(2020, 1, 1, tz="Europe/Amsterdam")
        }

operators_dag = DAG(
        '06-airflow-operators-dag',
        default_args=default_args,
        schedule_interval='@daily',
        catchup=False,
        is_paused_upon_creation=False
        )

spark_sql_step1 = CDEJobRunOperator(
        task_id='sql_job_new',
        dag=operators_dag,
        job_name='06_pysparksql'
        )

shell_step2 = BashOperator(
        task_id='bash',
        dag=operators_dag,
        bash_command='echo "Hello Airflow" '
        )

shell_jinja_step3 = BashOperator(
    task_id='bash_with_jinja',
    dag=operators_dag,
    bash_command='echo "yesterday={{ yesterday_ds }} | today={{ ds }}| tomorrow={{ tomorrow_ds }}"',
)

#Custom Python Method
def _print_context(**context):
    print(context)

print_context_step4 = PythonOperator(
    task_id="print_context",
    python_callable=_print_context,
    dag=operators_dag
)

#api_host = Variable.get("ran")
def handle_response(response):
    if response.status_code == 200:
        print("Received 200 Ok")
        return True
    else:
        print("Error")
        return False

http_task_step5 = SimpleHttpOperator(
    task_id="random_joke_api",
    method="GET",
    http_conn_id="random_joke_connection",
    endpoint="/jokes/programming/random",
    headers={"Content-Type":"application/json"},
    response_check=lambda response: handle_response(response),
    dag=operators_dag,
    do_xcom_push=True
)

def _print_random_joke(**context):
    return context['ti'].xcom_pull(task_ids='random_joke_api')

random_joke_step6 = PythonOperator(
    task_id="print_random_joke",
    python_callable=_print_random_joke,
    dag=operators_dag
)

spark_sql_step1 >> shell_step2 >> shell_jinja_step3 >> print_context_step4 >> http_task_step5 >> random_joke_step6
