#docker build -t <registry>/<username or project>/<name>:<tag> .
docker build -t docker.io/layer7api/workshop-init:1.0.0 .

#docker push <registry>/<username or project>/<name>:<tag>
docker push docker.io/layer7api/workshop-init:1.0.0