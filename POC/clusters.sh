#!/bin/bash

# Colors
BLUE="\033[0;34m"
BROWN="\033[0;33m"
CYAN="\033[1;36m"
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Server cluster
echo -e "\n${BROWN}Deploying server cluster...${NC}\n"
./create-kind-cluster.sh

# Client cluster
echo -e "\n${BROWN}Deploying client cluster...${NC}\n"
../usecases/common/utils/create-kind2-cluster.sh