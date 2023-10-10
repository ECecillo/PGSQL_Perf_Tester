#!/bin/bash

RESULT_DIR="requests_result/"
DATABASE_TO_QUERY="YOUR_DATABASE_NAME"
DATABASE_USER="YOUR_DATABASE_USER"
DATABASE_CONFIG_PATH="/etc/postgresql/REPLACE_WITH_YOUR_DATABASE_VERSION/main/postgresql.conf"

# Execute the command and filter to get the line containing the IPv4 address for enp1s0
ip_line=$(ip addr show | grep -A2 'enp1s0:' | grep 'inet ' | awk '{print $2}')
# Extract only the IP address without the subnet mask
vm=${ip_line%%/*}


mkdir -p $RESULT_DIR
# Function to execute SQL queries
execute_queries() {
    local suffix=$1
    for sql in *.sql; do
        echo "Executing request ${sql} ${suffix} 🔁 on $vm"
        filename=$(basename $sql .sql)
        psql -h localhost -p 5432 -U $DATABASE_USER -d $DATABASE_TO_QUERY -XqAt -f $sql >"$RESULT_DIR/result_${filename}_${suffix}.json"
        echo "Request ${sql} ${suffix} executed successfully ✅ on $vm"
    done
}
# Execute the queries without tuning
# execute_queries "Your_suffix"

# Create the index that you defined and execute the queries with it
# for sql in index_*.sql indexes.sql; do
#     if [[ -f "$sql" ]]; then
#         psql -h localhost -p 5432 -U $DATABASE_USER -d $DATABASE_TO_QUERY -XqAt -f "$sql"
#     fi
# done


# Execute the script VM_Script.bash that will modify the PGSQL database parameters 
# (Uncoment the line below if you want to execute the script but consider that it is very long)

# chmod +x postgresql_config_tester.bash
#./postgresql_config_tester.bash # Execute all possible combinations of parameters


# Replace the modified postgresql.conf with the original one sent by scp previously
sudo cp -f postgresql.conf 
sudo systemctl restart postgresql
echo "Reset of postgresql.conf executed successfully ✅ on $vm"
rm -f postgresql.conf # Remove the modified postgresql.conf
rm -f *.sql # Remove all sql files sent by scp
echo "All sql files removed successfully ✅ on $vm"

