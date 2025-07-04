#!/bin/bash

CURR_USER=$USER;
CURR_UID=$UID;
echo "Need root access for creating /data/coolify directory."
sudo bash -c "mkdir -p /data/coolify; chown $CURR_USER /data/coolify"

echo "Need root access for creating symlink /var/run/docker.sock => /run/user/$CURR_UID/podman/podman.sock"
sudo ln -s /run/user/$CURR_UID/podman/podman.sock /var/run/docker.sock

mkdir -p /data/coolify/{source,ssh,applications,databases,backups,services,proxy,webhooks-during-maintenance}
mkdir -p /data/coolify/ssh/{keys,mux}
mkdir -p /data/coolify/proxy/dynamic

ssh-keygen -f /data/coolify/ssh/keys/id.root@host.docker.internal -t ed25519 -N '' -C root@coolify

cat /data/coolify/ssh/keys/id.root@host.docker.internal.pub >> ./ssh/authorized_keys
chmod 700 ./ssh
chmod 600 ./ssh/authorized_keys

curl -fsSL https://cdn.coollabs.io/coolify/docker-compose.yml -o /data/coolify/source/docker-compose.yml
curl -fsSL https://cdn.coollabs.io/coolify/docker-compose.prod.yml -o /data/coolify/source/docker-compose.prod.yml
curl -fsSL https://cdn.coollabs.io/coolify/.env.production -o /data/coolify/source/.env
curl -fsSL https://cdn.coollabs.io/coolify/upgrade.sh -o /data/coolify/source/upgrade.sh

# The commented code wont work. 9999 is the userid of www-data user inside container.
# in the case of podman, it will be different. Need to do this using podman exec.
# chown -R 9999:root /data/coolify
chmod -R 700 /data/coolify

sed -i "s|APP_ID=.*|APP_ID=$(openssl rand -hex 16)|g" /data/coolify/source/.env
sed -i "s|APP_KEY=.*|APP_KEY=base64:$(openssl rand -base64 32)|g" /data/coolify/source/.env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$(openssl rand -base64 32)|g" /data/coolify/source/.env
sed -i "s|REDIS_PASSWORD=.*|REDIS_PASSWORD=$(openssl rand -base64 32)|g" /data/coolify/source/.env
sed -i "s|PUSHER_APP_ID=.*|PUSHER_APP_ID=$(openssl rand -hex 32)|g" /data/coolify/source/.env
sed -i "s|PUSHER_APP_KEY=.*|PUSHER_APP_KEY=$(openssl rand -hex 32)|g" /data/coolify/source/.env
sed -i "s|PUSHER_APP_SECRET=.*|PUSHER_APP_SECRET=$(openssl rand -hex 32)|g" /data/coolify/source/.env

podman network exists coolify || podman network create coolify


podman compose --env-file /data/coolify/source/.env -f /data/coolify/source/docker-compose.yml -f /data/coolify/source/docker-compose.prod.yml up -d --pull always --remove-orphans --force-recreate


echo "Waiting for 10 seconds to start containers. Some more changes need to be done after that"
sleep 10

echo "Fixing directory ownership"
podman exec -it --user root coolify chown www-data:root -R /var/www/html/storage/app/

echo "Patching coolify source code to bypass podman version check"
podmanVersion=$(podman -v | cut -d ' ' -f3)
podman exec -it  coolify sed -i "s#docker version|head -2|grep -i version#docker version|head -2|grep -i version| sed 's/$podmanVersion/24.0.0/g' #" /var/www/html/app/Livewire/Boarding/Index.php
