#!/bin/bash
# This script spins up the local TGI Inference Server. HF Model ID is a required parameters, quantization level is optional

pkill -SIGINT -f "^text-generation-server download-weights" & 
pkill -SIGINT -f '^text-generation-launcher' & 
pkill -SIGINT -f 'text-generation' & 

sleep 1

CUDA_MEMORY_FRACTION=0.85 # adjust the percentage of the GPU being used. Don't go above 0.95

if [ "$2" = "none" ]
then
    text-generation-launcher --model-id $1 --cuda-memory-fraction $CUDA_MEMORY_FRACTION --max-input-length 4000 --max-total-tokens 5000 --port 9090 &
else
    text-generation-launcher --model-id $1 --cuda-memory-fraction $CUDA_MEMORY_FRACTION --max-input-length 4000 --max-total-tokens 5000 --quantize $2 --port 9090 &
fi

sleep 30 # Model warm-up

URLS=("http://localhost:9090/info")

# for url in "${URLS[@]}"; do
#     # Curl each URL, only outputting the HTTP status code
#     status=$(curl -o /dev/null -s -w "%{http_code}" --max-time 3 "$url")
    
#     # Check if the status is not 200
#     if [[ $status -ne 200 ]]; then
#         echo "start-local.sh Error: $url returned HTTP code $status"
#         exit 1
#     fi
# done


start_time=$(date +%s)
count=0
url="http://localhost:9090/info"

while [ $(($(date +%s) - $start_time)) -lt 120 ]; do
    status_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$url")
    if [ "$status_code" == "000" ]; then
        count=$((count + 1))
        echo "Status code '000' detected ($count)"
    elif [ "$status_code" -ne "200" ]; then
        echo "start-local.sh Error: $url returned HTTP code $status_code"
        break
    fi
    sleep 20
done


sleep 1
exit 0
