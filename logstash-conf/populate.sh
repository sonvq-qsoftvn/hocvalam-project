#!/usr/bin/env bash

ADDRESS=$1

if [ -z $ADDRESS ]; then
  ADDRESS="localhost:9200"
fi

# Check that Elasticsearch is running
curl -s "http://$ADDRESS" 2>&1 > /dev/null
if [ $? != 0 ]; then
    echo "Unable to contact Elasticsearch at $ADDRESS"
    echo "Please ensure Elasticsearch is running and can be reached at http://$ADDRESS/"
    exit -1
fi

echo "WARNING, this script will delete the 'hocvalam-wiki' indices and re-index all data!"
echo "Press Control-C to cancel this operation."
echo
echo "Press [Enter] to continue."
read

# Delete the old index, swallow failures if it doesn't exist
curl -s -XDELETE "$ADDRESS/hocvalam-wiki" > /dev/null

# Create the next index using mapping.json
echo "Creating 'hocvalam-wiki' index..."
curl -s -XPOST "$ADDRESS/hocvalam-wiki" -d@$(dirname $0)/mapping.json

# Wait for index to become yellow
curl -s "$ADDRESS/hocvalam-wiki/_health?wait_for_status=yellow&timeout=10s" > /dev/null
echo
echo "Done creating 'hocvalam-wiki' index."

echo
echo "Indexing data..."

echo "Indexing types..."

/opt/logstash/bin/logstash -f hocvalam-wiki-remote-firstrun.conf

echo
echo "Done indexing!!!"


echo