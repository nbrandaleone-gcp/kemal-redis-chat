#!/bin/bash
## Toggles between non-secure websockets (ws) and secure websockets (wss)
sed -i '' 's@wss:\/\/@ws:\/\/@' ../views/index.ecr
