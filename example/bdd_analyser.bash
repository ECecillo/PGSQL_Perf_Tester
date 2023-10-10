#!/opt/homebrew/bin/bash

# Define the VMs
SMALL="192.168.246.163"
MEDIUM="192.168.246.206"
LARGE="192.168.246.183"

VMs=($MEDIUM $LARGE)
SSH_KEY="/Users/johndoe/.ssh/private_key"
HOST="ubuntu"
SQL_DIR="sql/"
SCRIPT_DIR="script/"
DEST_DIR="/home/$HOST/"
RESULT_DIR="result/"
CONFIG_DIR="conf"
LOCAL_RESULTS="/Users/johndoe/database_results"

# Copy/Replace SQL queries located in the query folder to VMs using scp ✅
for vm in "${VMs[@]}"; do
    {
        echo "Sending the requests to ${vm}:$DEST_DIR 🐳"
        scp -i $SSH_KEY -r $SQL_DIR/*.sql $HOST@$vm:$DEST_DIR
        scp -i $SSH_KEY $CONFIG_DIR/*.conf $HOST@$vm:$DEST_DIR
        scp -i $SSH_KEY $SCRIPT_DIR/*.bash $HOST@$vm:$DEST_DIR
    } &
done
wait

# Copy configuration files to specific VMs
scp -i $SSH_KEY -r $CONFIG_DIR/$LARGE/*.conf $HOST@$LARGE:$DEST_DIR
scp -i $SSH_KEY -r $CONFIG_DIR/$MEDIUM/*.conf $HOST@$MEDIUM:$DEST_DIR
scp -i $SSH_KEY -r $CONFIG_DIR/$SMALL/*.conf $HOST@$SMALL:$DEST_DIR

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
    scp -i $SSH_KEY -r $HOST@$vm:$DEST_DIR/$RESULT_DIR/result_\*.json $LOCAL_RESULTS/$vm/
    } &
done
wait

# # Locally, trigger the Python script to analyze the JSON files
# python3 analyze_results.py

