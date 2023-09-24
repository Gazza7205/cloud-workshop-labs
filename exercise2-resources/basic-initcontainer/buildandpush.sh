#docker build -t <registry>/<username or project>/<name>:<tag> .
docker build -t harbor.sutraone.com/mock/workshop-init:1.0.0 .

#docker push <registry>/<username or project>/<name>:<tag>
docker push harbor.sutraone.com/mock/workshop-init:1.0.0