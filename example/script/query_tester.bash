#!/bin/bash

RESULT_DIR="requests_result/"
# Execute the command and filter to get the line containing the IPv4 address for enp1s0
ip_line=$(ip addr show | grep -A2 'enp1s0:' | grep 'inet ' | awk '{print $2}')
# Extract only the IP address without the subnet mask
vm=${ip_line%%/*}

mkdir -p $RESULT_DIR
# Function to execute SQL queries
execute_queries() {
    local suffix=$1
    for sql in "query1.sql" "query2.sql" "query3.sql"; do
        echo "Executing request ${sql} 🔁 on $vm"
        filename=$(basename $sql .sql)
        psql -h localhost -p 5432 -U etum2 -d local_insee_deces -XqAt -f $sql >"$RESULT_DIR/result_${filename}_${suffix}.json"
        echo "Request ${sql} ${suffix} executed successfully ✅ on $vm"
    done
}
# Execute the queries without tuning
execute_queries "no_index"

# Create the index and execute the queries with it
psql -h localhost -p 5432 -U etum2 -d local_insee_deces -XqAt -f "indexes.sql"
execute_queries "with_indexes"

# Execute the queries with the index and modified configuration
execute_queries "with_indexes_and_edited_config"

# Execute the script VM_Script.bash that will modify the PGSQL database parameters
chmod +x postgresql_config_tester.bash
# ./postgresql_config_tester.bash # Execute all possible combinations of parameters
# Reset the created index
psql -h localhost -p 5432 -U etum2 -d local_insee_deces -XqAt -f "reset_indexes.sql"
echo "Indexes reset successfully executed ✅ on $vm"
# Replace the modified postgresql.conf with the original one sent by scp previously
sudo cp -f postgresql.conf /etc/postgresql/15/main/postgresql.conf
sudo systemctl restart postgresql
echo "Reset of postgresql.conf executed successfully ✅ on $vm"
rm -f postgresql.conf # Remove the modified postgresql.conf
rm -f *.sql # Remove all sql files sent by scp
echo "All sql files removed successfully ✅ on $vm"

