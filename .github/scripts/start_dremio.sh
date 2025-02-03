# #!/bin/bash
# set -e

# echo "Starting Dremio service..."

# docker run -d \
#   --network ci-network \
#   --name dremio \
#   -p 31010:31010 \
#   -p 9047:9047 \
#   -e "DREMIO_JAVA_SERVER_EXTRA_OPTS=-Ddebug.addDefaultUser=true" \
#   dremio/dremio-oss

# echo "Dremio service started."

#!/bin/bash
set -e

echo "Checking Dremio Enterprise service health..."

# Check if Dremio is running by hitting the health endpoint
if curl -s --head  --request GET http://localhost:9047 | grep "200 OK" > /dev/null; then 
   echo "Dremio Enterprise service is running."
else
   echo "Dremio Enterprise service is not running. Please start the service."
   exit 1
fi
