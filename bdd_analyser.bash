#!/opt/homebrew/bin/bash

# Define the VMs

VMs=("Put your VM IPs here") # Look at the example if you want to know how to do it.
SSH_KEY="SSH_PRIVATE_KEY_PATH"
SQL_DIR="sql/"
SCRIPT_DIR="script/"
DEST_DIR="DESTINATION_DIR_ON_YOUR_VM" # We suppose that there are the same directories on each VM
HOST="YOUR_HOST"
RESULT_DIR="result/"
CONFIG_DIR="conf"
LOCAL_RESULTS="RELATE_OR_ABSOLUTE_PATH/database_results"

# Copy/Replace SQL queries located in the query folder to VMs using scp ✅
for vm in "${VMs[@]}"; do
    {
        echo "Sending the requests to ${vm}:$DEST_DIR 🐳"
        scp -i $SSH_KEY -r $SQL_DIR/*.sql $HOST@$vm:$DEST_DIR
        scp -i $SSH_KEY $CONFIG_DIR/*.conf $HOST@$vm:$DEST_DIR
        if [[ -f "./${CONFIG_DIR}/${vm}/custom_postgresql_config.conf" ]]; then
          scp -i $SSH_KEY $CONFIG_DIR/$vm/custom_postgresql_config.conf ubuntu@$vm:$DEST_DIR/
        fi
        scp -i $SSH_KEY $SCRIPT_DIR/*.bash $HOST@$vm:$DEST_DIR
    } &
done
wait


# Loop through each VM
for vm in "${VMs[@]}"; do
    {
        # Connect to each VM via SSH using the private key and execute the following commands
        echo "Connecting to VM $vm ♻️"
        ssh -i $SSH_KEY $HOST@$vm <<'ENDSSH'
        echo "Successful connection 🔌"
        chmod +x query_tester.bash
        echo "Launching the query tester 🚀"
        ./query_tester.bash
        echo "Query tester completed 🏁"
ENDSSH

    echo "Fetching results 📂 from VM $vm"
    # Copy the resulting files to the local machine
    # Make sure it is configured ❗️
    scp -i $SSH_KEY -r $HOST@$vm:$DEST_DIR/$RESULT_DIR/result_\*.json $LOCAL_RESULTS/$vm/
    } &
done
wait

