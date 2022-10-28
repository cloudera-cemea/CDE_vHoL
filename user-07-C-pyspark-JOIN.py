from pyspark.sql import SparkSession
from pyspark.sql.types import Row, StructField, StructType, StringType, IntegerType
import os
import sys

data_lake_name = "s3a://go01-demo/"
s3BucketName = "s3a://go01-demo/cde-workshop/cardata-csv/"
# Your Username Here:
username = "user_test_3"

spark = SparkSession \
    .builder \
    .appName("PySpark SQL") \
    .config("spark.yarn.access.hadoopFileSystems", data_lake_name)\
    .getOrCreate()

spark.sql("SELECT * FROM {0}_CAR_DATA.LEFT_TABLE L\
            INNER JOIN {0}_CAR_DATA.RIGHT_TABLE R\
            ON L.PERSON_NAME = R.PERSON_NAME ".format(username)).show()
