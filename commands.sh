curl -X POST -H "Content-Type: application/json" --data @jdbc-sink-connector-a.json http://localhost:8083/connectors
curl -X POST -H "Content-Type: application/json" --data @jdbc-sink-connector-b.json http://localhost:8083/connectors
curl -X POST -H "Content-Type: application/json" --data @jdbc-source-connector.json http://localhost:8083/connectors

docker-compose exec postgres_a psql -U user -d db_a -c "SELECT * FROM tides_table;"
docker-compose exec postgres_b psql -U user -d db_b -c "SELECT * FROM tides_table;"

curl -X GET http://localhost:8083/connectors/jdbc-source-connector/status | jq
curl -X GET http://localhost:8083/connectors/jdbc-sink-connector-a/status | jq
curl -X GET http://localhost:8083/connectors/jdbc-sink-connector-b/status | jq



docker-compose exec ksqldb-cli ksql http://ksqldb-server:8088


docker-compose up --build
docker rm -v -f $(docker ps -qa)
docker volume prune


<<source_stream
DROP STREAM IF EXISTS source_stream;

CREATE STREAM source_stream (
    id INT,
    category VARCHAR,
    value INT,
    updated_at TIMESTAMP
) WITH (
    KAFKA_TOPIC='jdbc-source_table',
    VALUE_FORMAT='AVRO',
    PARTITIONS=2
);
source_stream

<<stream_a
DROP STREAM IF EXISTS stream_a;

CREATE STREAM stream_a AS
SELECT id, category, value, updated_at
FROM source_stream
WHERE category = 'A';
stream_a

<<stream_b
DROP STREAM IF EXISTS stream_b;

CREATE STREAM stream_b AS
SELECT id, category, value, updated_at
FROM source_stream
WHERE category = 'B';
stream_b


SELECT * FROM source_stream EMIT CHANGES;
SELECT * FROM stream_a EMIT CHANGES;
SELECT * FROM stream_b EMIT CHANGES;




docker-compose exec postgres_source psql -U user -d testdb
docker-compose exec postgres_a psql -U user -d db_a
docker-compose exec postgres_b psql -U user -d db_b


curl -X GET http://localhost:8081/subjects/jdbc-source_table-value/versions/latest | jq

curl -X DELETE http://localhost:8081/subjects/jdbc-source_table-value/versions/1
curl -X DELETE http://localhost:8081/subjects/STREAM_A-value/versions/1
curl -X DELETE http://localhost:8081/subjects/STREAM_B-value/versions/1

curl -X DELETE http://localhost:8083/connectors/jdbc-source-connector
curl -X DELETE http://localhost:8083/connectors/jdbc-sink-connector-a
curl -X DELETE http://localhost:8083/connectors/jdbc-sink-connector-b



## Verical split

<<source_stream
DROP STREAM IF EXISTS source_stream;

CREATE STREAM source_stream (
    id INT,
    category VARCHAR,
    value INT,
    updated_at TIMESTAMP
) WITH (
    KAFKA_TOPIC='jdbc-source_table',
    VALUE_FORMAT='AVRO',
    PARTITIONS=2
);
source_stream

<<ver_a
CREATE STREAM stream_a AS
SELECT id, category
FROM source_stream;
ver_a

<<ver_b
CREATE STREAM stream_b AS
SELECT id, value AS score, updated_at
FROM source_stream;
ver_b