# This demo briefly shows how to push x2 version of code into Cloud Run,
# switch between the versions, and review logs and metrics.

## Setup redis
export REDISHOST=$(gcloud redis instances describe redis-chat --region $REGION --format "value(host)")

## Deploy "standard" version of a container into Cloud Run
gcloud run deploy websockets \
	--allow-unauthenticated \
	--image nbrand/kemal-redis-chat:0.1 \
	--allow-unauthenticated \
	--region us-central1 \
	--max-instances 10 \
	--concurrency 100 \
	--timeout 3600 \
	--network=default \
	--subnet=default \
	--vpc-egress=private-ranges-only \
	--set-env-vars REDIS=${REDISHOST} \
	--set-env-vars DEBUG="false"

### Notice h1 tag is Chatroom

## Deply a new revision, with 50% traffic
gcloud run deploy --image nbrand/kemal-redis-chat:0.2 --no-traffic

## Deploy a new tagged revision
gcloud run deploy myservice --image nbrand/kemal-redis-chat:0.2  \
    --no-traffic --tag green \
    
