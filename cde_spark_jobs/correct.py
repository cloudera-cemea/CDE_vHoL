from pyspark.sql import SparkSession
from great_expectations.dataset.sparkdf_dataset import SparkDFDataset


# create spark session
spark = SparkSession.builder.appName("VALIDATE").getOrCreate()

USERNAME = spark._sc.sparkUser()
print(f"RUNNING AS USERNAME: {USERNAME}")

# address the data quality issue with spark
sales_df = spark.sql(f"SELECT * FROM car_data_{USERNAME}.sales")
sales_df = sales_df.dropDuplicates(["customer_id", "VIN"])
sales_df.createOrReplaceTempView("sales_df")
spark.sql(f"INSERT OVERWRITE car_data_{USERNAME}.sales SELECT * FROM sales_df")

print("FINISHED INSERT OVERWRITE JOB TO ADDRESS THE DATA QUALITY ISSUE.")
