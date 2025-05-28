#!/bin/bash
#Hii_Namaste_Ramyaa
#yaml_file_changed

# Paths
LOG_DIR="../logs"
LOG_FILE="$LOG_DIR/log.txt"
SCRIPT_LOG="$LOG_DIR/script_run.log"

# Ensure logs directory exists
mkdir -p "$LOG_DIR"

# Function to log messages with local timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$SCRIPT_LOG"
}

log "Script started."

# Generate simulated login logs
log "Generating dynamic login logs..."
> "$LOG_FILE"  # Clear previous logs

USERS=("eshwar" "admin" "user01" "testuser" "devops" "qauser" "dhanush")
for i in {1..5}; do
    USER=${USERS[$RANDOM % ${#USERS[@]}]}
    IP="192.168.1.$((RANDOM % 100 + 1))"
    # Simulate a random time in the last 5 minutes (in local time)
    OFFSET=$((RANDOM % 300))
    EVENT_EPOCH=$(($(date +%s) - OFFSET))
    EVENT_TIME_LOCAL=$(date -d "@$EVENT_EPOCH" '+%Y-%m-%d %H:%M:%S')
    MESSAGE="User $USER logged in successfully from IP $IP at $EVENT_TIME_LOCAL"
    echo "$MESSAGE" >> "$LOG_FILE"
done

log "Collected login messages:"
cat "$LOG_FILE" | tee -a "$SCRIPT_LOG"

# Send each login event to Splunk HEC
log "Sending login events to Splunk HEC..."
while IFS= read -r line; do
    # Extract the local event time from the message
    EVENT_EPOCH=$(date +%s)  # You can use the same OFFSET here if needed
    curl --silent --output /dev/null \
         -k https://prd-p-xugh6.splunkcloud.com:8088/services/collector \
         -H "Authorization: Splunk 0202e8d8-f18c-4424-ab11-ad4d805927b1" \
         -H "Content-Type: application/json" \
         -d "{
                \"time\": $EVENT_EPOCH,
                \"event\": \"$line\",
                \"sourcetype\": \"automatic\",
                \"index\": \"harness_test\"
             }"

    if [ $? -eq 0 ]; then
        log "✅ Sent login event at $EVENT_EPOCH: $line"
    else
        log "❌ Failed to send login event at $EVENT_EPOCH: $line"
    fi
done < "$LOG_FILE"

log "Script finished."
