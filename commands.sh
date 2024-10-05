# start docker
docker rm -v -f $(docker ps -qa)
docker volume prune
docker-compose up --build


# create streams
docker-compose exec ksqldb-cli ksql http://ksqldb-server:8088

<<source_stream
DROP STREAM IF EXISTS source_stream;

CREATE STREAM source_stream (
    "id" INT,
    "category" VARCHAR,
    "value" INT,
    "updated_at" TIMESTAMP
) WITH (
    KAFKA_TOPIC='jdbc-source_table',
    VALUE_FORMAT='AVRO',
    PARTITIONS=1
);
source_stream

<<streams
CREATE STREAM stream_a AS
SELECT "id" as "source_id", "value", "updated_at"
FROM source_stream;

CREATE STREAM stream_b AS
SELECT "id" AS "source_id", "category", "updated_at"
FROM source_stream;
streams

SELECT * FROM source_stream EMIT CHANGES;
SELECT * FROM stream_a EMIT CHANGES;
SELECT * FROM stream_b EMIT CHANGES;

# Create sink connectors
curl -X POST -H "Content-Type: application/json" --data @jdbc-sink-connector-a.json http://localhost:8083/connectors
curl -X POST -H "Content-Type: application/json" --data @jdbc-sink-connector-b.json http://localhost:8083/connectors

# Source should be last
curl -X POST -H "Content-Type: application/json" --data @jdbc-source-connector.json http://localhost:8083/connectors


# Check connector status
curl -X GET http://localhost:8083/connectors/jdbc-source-connector/status | jq
curl -X GET http://localhost:8083/connectors/jdbc-sink-connector-a/status | jq
curl -X GET http://localhost:8083/connectors/jdbc-sink-connector-b/status | jq


docker-compose exec postgres_a psql -U user -d db_a -c "SELECT * FROM tides_table;"
docker-compose exec postgres_b psql -U user -d db_b -c "SELECT * FROM tides_table;"


# Delete connectors
curl -X DELETE http://localhost:8083/connectors/jdbc-source-connector
curl -X DELETE http://localhost:8083/connectors/jdbc-sink-connector-a
curl -X DELETE http://localhost:8083/connectors/jdbc-sink-connector-b


# Connect to source/sink databases
docker-compose exec postgres_source psql -U user -d testdb
docker-compose exec postgres_a psql -U user -d db_a
docker-compose exec postgres_b psql -U user -d db_b


# Get the schema of the latest version.
curl -X GET http://localhost:8081/subjects/jdbc-source_table-value/versions/latest | jq

# Delete schemas
curl -X DELETE http://localhost:8081/subjects/jdbc-source_table-value/versions/1
curl -X DELETE http://localhost:8081/subjects/STREAM_A-value/versions/1
curl -X DELETE http://localhost:8081/subjects/STREAM_B-value/versions/1





# Access the Kafka container
docker exec -it <kafka-container-name> /bin/bash

# Describe each consumer group
kafka-consumer-groups --bootstrap-server localhost:9092 --group _confluent-controlcenter-7-6-0-1 --describe
kafka-consumer-groups --bootstrap-server localhost:9092 --group connect-jdbc-sink-connector-b --describe
kafka-consumer-groups --bootstrap-server localhost:9092 --group _confluent-ksql-default_query_CSAS_STREAM_A_3 --describe
kafka-consumer-groups --bootstrap-server localhost:9092 --group _confluent-ksql-default_transient_transient_STREAM_A_4191922460426149900_1728123874472 --describe
kafka-consumer-groups --bootstrap-server localhost:9092 --group connect-jdbc-sink-connector-a --describe
kafka-consumer-groups --bootstrap-server localhost:9092 --group _confluent-ksql-default_query_CSAS_STREAM_B_5 --describe
kafka-consumer-groups --bootstrap-server localhost:9092 --group _confluent-controlcenter-7-6-0-1-command --describe