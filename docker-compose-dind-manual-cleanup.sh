#!/bin/bash

# to be run from within a docker exec -it <dind> sh

docker ps | awk '{print $1}' | while read line; do 
	docker stop $line
	docker rm $line
done
