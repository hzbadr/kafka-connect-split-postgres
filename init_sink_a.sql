CREATE TABLE table_a (
    "id" SERIAL PRIMARY KEY,
    "source_id" INT NOT NULL,
    "value" INT NOT NULL,
    "updated_at" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX source_id_idx ON table_a (source_id);