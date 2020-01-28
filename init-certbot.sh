#!/bin/bash

if ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Error: docker-compose is not installed.' >&2
  exit 1
fi

if [ "$#" -eq 0 ]; then
  echo 'Error: No domains given. First argument is the primary domain, other args are used for "common" names in the certificate.' >&2
  exit 1
fi

domains=("$@")
rsa_key_size=4096
CERTBOT_PATH="/srv/certbot/etc"
APACHE_PATH="./apache"
email="info@spbsoftwareontwikkeling.nl" # Adding a valid address is strongly recommended TODO MOVE TO ARGS
staging=0 # Set to 1 if you're testing your setup to avoid hitting request limits

if [ -d "$CERTBOT_PATH" ]; then
  read -p "Existing data found for $domains. Continue and replace existing certificate? (y/N) " decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    exit
  fi
fi

# Check if the recommended dh params already exist.
if [ ! -e "$CERTBOT_PATH/ssl-dhparams.pem" ]; then
  echo "### Downloading recommended TLS parameters"
  mkdir -p "$CERTBOT_PATH"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$CERTBOT_PATH/ssl-dhparams.pem"
  echo
fi

# Create dummy certificate so apache can start without crashing.
echo "### Creating dummy certificate for $domains"
path="/etc/letsencrypt/live/$domains"
mkdir -p "$CERTBOT_PATH/live/$domains"
docker-compose run --rm --entrypoint "\
  openssl req -x509 -nodes -newkey rsa:1024 -days 1\
    -keyout '$path/privkey.pem' \
    -out '$path/fullchain.pem' \
    -subj '/CN=localhost'" certbot
echo

echo "### Starting apache"
docker-compose up --force-recreate -d apache
echo

echo "### Deleting dummy certificate for $domains"
docker-compose run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/$domains && \
  rm -Rf /etc/letsencrypt/archive/$domains && \
  rm -Rf /etc/letsencrypt/renewal/$domains.conf" certbot
echo


echo "### Requesting Letsencrypt certificate for $domains"
#Join $domains to -d args
domain_args=""
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done

# Register email so you'll get a notice if renewal fails/certificate expires.
case "$email" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $email" ;;
esac

if [ $staging != "0" ]; then
  staging_arg="--staging";
  echo '### Staging mode enabled.';
fi

docker-compose run --rm --entrypoint "\
  certbot certonly --webroot -w /usr/local/certbot/htdocs \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $rsa_key_size \
    --agree-tos \
    --force-renewal" certbot
echo

echo "### Reloading apache"
docker-compose exec apache apachectl -k graceful
