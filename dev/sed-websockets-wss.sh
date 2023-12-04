#!/bin/bash
## Toggles between non-secure websockets (ws) and secure websockets (wss)
sed -i '' 's@ws:\/\/@wss:\/\/@' ../views/index.ecr
