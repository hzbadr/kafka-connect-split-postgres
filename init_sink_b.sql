CREATE TABLE table_b (
    id SERIAL PRIMARY KEY,
    source_id INT NOT NULL,
    category VARCHAR(50) NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);