 # Demo.md
 This demo briefly shows how to push x2 version of code into Cloud Run,
 switch between the versions, and review logs and metrics.
 https://cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration

## Setup redis
```bash
export REDISHOST=$(gcloud redis instances describe redis-chat --region $REGION --format "value(host)")
```

## Deploy "standard" version of a container into Cloud Run
```bash
gcloud beta run deploy websockets \
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
```

### Notice h1 tag is Chatroom name

## Deply a new revision, with 0% traffic
```bash
gcloud run deploy websockets --image nbrand/kemal-redis-chat:0.2 \
    --update-env-vars DEBUG=true --no-traffic

gcloud run revisions list --service websockets
```

### Verify DEBUG env variable has now been set

## Split traffic
```bash
gcloud run services update-traffic websockets \
    --to-revisions websockets-00002-6cs=50,websockets-00001-xtm=50
    
gcloud run services update-traffic websockets --to-latest
```

### Notice h1 tag has changed

## Review logs
```bash
gcloud beta run services logs read websockets \
    --limit=20 --project testing-355714
```

---

## Deploy a new tagged revision
During testing, the creating a tagged version took a signficant
amount of time.  I suspect it was due to the creation of a unique
DNS name in real-time. It worked fine the second time. Strange...

```bash
gcloud run deploy websockets --image nbrand/kemal-redis-chat:0.2  \
    --update-env-vars DEBUG=true --no-traffic --tag green
    
gcloud run services update-traffic websockets --remove-tags green

gcloud run services update-traffic websockets --to-tags green=100
```

---
