#!/bin/sh

if [[ -z "${EMAIL}" ]]; then
  echo "EMAIL env var must be set"
  exit 1
fi

if [[ -z "${CLOUDFLARE_TOKEN}" ]]; then
  echo "CLOUDFLARE_TOKEN env var must be set"
  exit 1
fi

if [[ -z "${DOMAIN}" ]]; then
  echo "DOMAIN env var must be set"
  exit 1
fi

certbot register --non-interactive --agree-tos -m $EMAIL

export ACCOUNT_PARENT_PATH=/etc/letsencrypt/accounts/acme-v02.api.letsencrypt.org/directory
export ACCOUNT_ID=$(ls $ACCOUNT_PARENT_PATH)
vault kv put secret/lets-encrypt/account/extra_details "account_id=$ACCOUNT_ID"
for i in meta private_key regr; do
  vault kv put "secret/lets-encrypt/account/$i" "@$ACCOUNT_PARENT_PATH/$ACCOUNT_ID/$i.json"
done

echo "dns_cloudflare_api_token = $CLOUDFLARE_TOKEN" > /etc/letsencrypt/cloudflare.ini
chmod 600 /etc/letsencrypt/cloudflare.ini
vault kv put secret/cloudflare-dns-token "token=$CLOUDFLARE_TOKEN"

certbot certonly --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini -d "*.$DOMAIN"
vault kv put \
  "secret/lets-encrypt/certificates/$DOMAIN"  \
  "cert=@/etc/letsencrypt/live/$DOMAIN/cert.pem" \
  "chain=@/etc/letsencrypt/live/$DOMAIN/chain.pem" \
  "privkey=@/etc/letsencrypt/live/$DOMAIN/privkey.pem"