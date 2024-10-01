# Open a file to write the SQL statements
with open("./init_source.sql", "w") as file:
    # Write the table creation statement
    file.write("""
CREATE TABLE source_table (
    id SERIAL PRIMARY KEY,
    category VARCHAR(50) NOT NULL,
    value INT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO source_table (category, value, updated_at) VALUES
""")

    # Generate 10,000 records following the specified pattern
    for i in range(1, 100001):
        if i % 4 == 1:
            file.write("('A', 10, CURRENT_TIMESTAMP),\n")
        elif i % 4 == 2:
            file.write("('B', 20, CURRENT_TIMESTAMP),\n")
        elif i % 4 == 3:
            file.write("('A', 30, CURRENT_TIMESTAMP),\n")
        else:
            file.write("('B', 40, CURRENT_TIMESTAMP),\n")

    # Remove the last comma and add a semicolon to end the statement
    file.seek(file.tell() - 2, 0)
    file.write(";\n")