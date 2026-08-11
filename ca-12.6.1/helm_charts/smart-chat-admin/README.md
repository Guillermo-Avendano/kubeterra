## Deployment instructions on Ubuntu/WSL


checkout the helm chart in a folder

helm pull https://wal-artifactory.rocketsoftware.com:443/artifactory/bicy-helm-dev-wal/$HelmpkgVersion --user "xxxx" --password "xxxx"

set up keys:
Add an .env in smart-chat/.env
and add your openapi key

OPENAI_API_KEY=XXXX

Pull the docker image

docker pull wal-artifactory.rocketsoftware.com:6575/smart-chat:$Version

make a staging directory for your docker images, to avoid messing with registries

mkdir $HOME/images

sudo docker save wal-artifactory.rocketsoftware.com:6575/smart-chat:$Version -o $HOME/images/smart-chat.tar


great. Now we'll make a k3d environment and mount that image directory, so we can avoid registries.

k3d cluster delete

sudo k3d cluster create -v $HOME/images/:/var/lib/rancher/k3s/agent/images

make our secret from our .env file.

sudo kubectl create secret generic smart-chat-secrets --from-env-file=.env

whew. ok. now we install the components.

cd smart-chat

sudo helm install smart-chat .



Ok. Fine. Now we have to do port forwarding to get to our smart-chat instance, irritatingly.

POD=$(sudo kubectl get pods -n default -l "app.kubernetes.io/name=smart-chat" -o jsonpath="{.items[0].metadata.name}") && sudo kubectl port-forward $POD 20365:8000


Forwarding from 127.0.0.1:20365 -> 8000
Forwarding from [::1]:20365 -> 8000
Handling connection for 20365

now you can point a browser at 127.0.0.1:20365
http://127.0.0.1:20365/docs should pull the swagger json