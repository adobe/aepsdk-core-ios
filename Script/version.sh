#!/usr/bin/env bash

set -e

if which jq >/dev/null; then
    echo "jq is installed"
else
    echo "error: jq not installed.(brew install jq)"
fi

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'

#  ---- enable the following code after the new pod has been released. ----
# LATEST_PUBLIC_VERSION=$(pod spec cat AEPRulesEngine | jq '.version' | tr -d '"')
# echo "Latest public version is: ${BLUE}$LATEST_PUBLIC_VERSION${NC}"
# if [[ "$1" == "$LATEST_PUBLIC_VERSION" ]]; then
#     echo "${RED}[Error]${NC} $LATEST_PUBLIC_VERSION has been released!"
#     exit -1
# fi
echo "Target version - ${BLUE}$1${NC}"
echo "------------------AEPCore-------------------"
PODSPEC_VERSION_IN_APECore=$(pod ipc spec AEPCore.podspec | jq '.version' | tr -d '"')
echo "Local podspec version - ${BLUE}${PODSPEC_VERSION_IN_APECore}${NC}"
SOUCE_CODE_VERSION_IN_APECore=$(cat ./AEPCore/Sources/core/CoreConstants.swift | egrep '\s*EXTENSION_VERSION\s*=\s*\"(.*)\"' | ruby -e "puts gets.scan(/\"(.*)\"/)[0] " | tr -d '"')
echo "Souce code version - ${BLUE}${SOUCE_CODE_VERSION_IN_APECore}${NC}"

if [[ "$1" == "$PODSPEC_VERSION_IN_APECore" ]] && [[ "$1" == "$SOUCE_CODE_VERSION_IN_APECore" ]]; then
    echo "${GREEN}Pass!${NC}"
else
    echo "${RED}[Error]${NC} Version do not match!"
    exit -1
fi

echo "----------------AEPIdentity-----------------"
PODSPEC_VERSION_IN_AEPIdentity=$(pod ipc spec AEPIdentity.podspec | jq '.version' | tr -d '"')
echo "Local podspec version - ${BLUE}${PODSPEC_VERSION_IN_AEPIdentity}${NC}"
SOUCE_CODE_VERSION_IN_AEPIdentity=$(cat ./AEPIdentity/Sources/IdentityConstants.swift | egrep '\s*EXTENSION_VERSION\s*=\s*\"(.*)\"' | ruby -e "puts gets.scan(/\"(.*)\"/)[0] " | tr -d '"')
echo "Souce code version - ${BLUE}${SOUCE_CODE_VERSION_IN_AEPIdentity}${NC}"

if [[ "$1" == "$PODSPEC_VERSION_IN_AEPIdentity" ]] && [[ "$1" == "$SOUCE_CODE_VERSION_IN_AEPIdentity" ]]; then
    echo "${GREEN}Pass!${NC}"
else
    echo "${RED}[Error]${NC} Version do not match!"
    exit -1
fi

echo "-----------------AEPLifecycle------------------"
PODSPEC_VERSION_IN_AEPLifecycle=$(pod ipc spec AEPLifecycle.podspec | jq '.version' | tr -d '"')
echo "Local podspec version - ${BLUE}${PODSPEC_VERSION_IN_AEPLifecycle}${NC}"
SOUCE_CODE_VERSION_IN_AEPLifecycle=$(cat ./AEPLifecycle/Sources/LifecycleConstants.swift | egrep '\s*EXTENSION_VERSION\s*=\s*\"(.*)\"' | ruby -e "puts gets.scan(/\"(.*)\"/)[0] " | tr -d '"')
echo "Souce code version - ${BLUE}${SOUCE_CODE_VERSION_IN_AEPLifecycle}${NC}"

if [[ "$1" == "$PODSPEC_VERSION_IN_AEPLifecycle" ]] && [[ "$1" == "$SOUCE_CODE_VERSION_IN_AEPLifecycle" ]]; then
    echo "${GREEN}Pass!${NC}"
else
    echo "${RED}[Error]${NC} Version do not match!"
    exit -1
fi

echo "-----------------AEPSignal------------------"
PODSPEC_VERSION_IN_AEPSignal=$(pod ipc spec AEPLifecycle.podspec | jq '.version' | tr -d '"')
echo "Local podspec version - ${BLUE}${PODSPEC_VERSION_IN_AEPSignal}${NC}"
SOUCE_CODE_VERSION_IN_AEPSignal=$(cat ./AEPSignal/Sources/SignalConstants.swift | egrep '\s*EXTENSION_VERSION\s*=\s*\"(.*)\"' | ruby -e "puts gets.scan(/\"(.*)\"/)[0] " | tr -d '"')
echo "Souce code version - ${BLUE}${SOUCE_CODE_VERSION_IN_AEPSignal}${NC}"

if [[ "$1" == "$PODSPEC_VERSION_IN_AEPSignal" ]] && [[ "$1" == "$SOUCE_CODE_VERSION_IN_AEPSignal" ]]; then
    echo "${GREEN}Pass!${NC}"
else
    echo "${RED}[Error]${NC} Version do not match!"
    exit -1
fi

echo "-----------------AEPServices------------------"
PODSPEC_VERSION_IN_AEPServices=$(pod ipc spec AEPServices.podspec | jq '.version' | tr -d '"')
echo "Local podspec version - ${BLUE}${PODSPEC_VERSION_IN_AEPServices}${NC}"
# SOUCE_CODE_VERSION_IN_AEPServices=$(cat ./AEPSignal/Sources/SignalConstants.swift | egrep '\s*EXTENSION_VERSION\s*=\s*\"(.*)\"' | ruby -e "puts gets.scan(/\"(.*)\"/)[0] " | tr -d '"')
# echo "Souce code version - ${BLUE}${SOUCE_CODE_VERSION_IN_AEPServices}${NC}"

# if [[ "$1" == "$PODSPEC_VERSION_IN_AEPServices" ]] && [[ "$1" == "$SOUCE_CODE_VERSION_IN_AEPServices" ]]; then
if [[ "$1" == "$PODSPEC_VERSION_IN_AEPServices" ]]; then
    echo "${GREEN}Pass!${NC}"
else
    echo "${RED}[Error]${NC} Version do not match!"
    exit -1
fi
exit 0
