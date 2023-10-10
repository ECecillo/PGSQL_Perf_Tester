#!/bin/bash

# Configurations to test
CONFIG_VALUES=(
  "YOUR_CONFIG_NAME CONFIG_VALUE ...."
)
DATABASE_NAME="YOUR_DATABASE_NAME"
DATABASE_USER="YOUR_DATABASE_USER"
DATABASE_CONFIG_PATH="/etc/postgresql/REPLACE_WITH_YOUR_DATABASE_VERSION/main/postgresql.conf"

# Generate all possible combinations and store them in an array
COMBINATIONS=()

for ((i = 1; i < 32; i++)); do
  COMB=""
  for ((j = 0; j < 5; j++)); do
    if ((($i >> $j) & 1)); then
      config_name=$(echo ${CONFIG_VALUES[$j]} | cut -d' ' -f1)
      COMB="$COMB $config_name"
    fi
  done
  COMBINATIONS+=("$COMB")
done

# Function to modify the PostgreSQL configuration file
modify_postgresql_conf() {
  local key="$1"
  local value="$2"
  local conf_file="$3"
  sudo sed -i "s/^${key} = .*/${key} = ${value}/" "$conf_file"
}

wait_for_postgres() {
  local max_attempts=10
  local attempt=0
  local delay=5 # Delay in seconds

  echo "Waiting for PostgreSQL to be ready..."

  until psql -h localhost -p 5432 -U $DATABASE_USER -d $DATABASE_NAME -c '\q' 2>/dev/null; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
      echo "PostgreSQL is not ready after $max_attempts attempts. Exiting."
      exit 1
    fi
    echo "Attempt $attempt failed. Retrying in $delay seconds..."
    sleep $delay
  done

  echo "PostgreSQL is ready!"
}

# Loop through each configuration combination
for combination in "${COMBINATIONS[@]}"; do
  echo "Combination: $combination"
  sudo cp $DATABASE_CONFIG_PATH $DATABASE_CONFIG_PATH.bak
  echo "Backup of postgresql.conf 📑"

  for config_data in "${CONFIG_VALUES[@]}"; do
    config_name=$(echo $config_data | cut -d' ' -f1)
    value1=$(echo $config_data | cut -d' ' -f2)
    value2=$(echo $config_data | cut -d' ' -f3)

    # If the config name is in the combination, then modify it
    if [[ $combination == *$config_name* ]]; then
      for value in $value1 $value2; do
        modify_postgresql_conf "$config_name" "$value" "${DATABASE_CONFIG_PATH}"
        echo "Configuration $config_name modified to $value 🛠️"

        # Restart PostgreSQL to apply the changes
        sudo service postgresql restart
        echo "PostgreSQL restarted 🔄"

        wait_for_postgres
        # Execute SQL queries with the modified configuration
      for sql in *.sql; do
          filename=$(basename $sql .sql)
          psql -h localhost -p 5432 -U $DATABASE_USER -d $DATABASE_NAME -XqAt -f $sql >"result_${combination}_${value}_${filename}.json"
          echo "Query ${sql} successfully executed with combination $combination and value $value ✅"
        done
      done
    fi
  done
done

