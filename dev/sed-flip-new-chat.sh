#!/bin/bash
## Flips the index HTML page to show a different H1 header
sed -i 's@<h1>Chat Room</h1>@<h1>My <b style='\''color:red;'\''>NEW</b> Chat Room</h1>@g' ../views/index.ecr
