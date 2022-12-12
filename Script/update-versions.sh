#!/bin/bash

# make this script executable from terminal:
# chmod 755 update-versions.sh

set -e # Any subsequent(*) commands which fail will cause the shell script to exit immediately

ROOT_DIR=$(git rev-parse --show-toplevel)
LINE="================================================================================"
VERSION_REGEX="[0-9]+\.[0-9]+\.[0-9]+"
DEPENDENCIES=none

# make a "dictionary" to help us find the correct spm repo per dependency (if necessary)
# IMPORTANT - this will be used in a regex search so escape special chars
# usage :
# getRepo AEPCore

declare "repos_AEPCore=https:\/\/github\.com\/adobe\/aepsdk-core-ios\.git"
declare "repos_AEPRulesEngine=https:\/\/github\.com\/adobe\/aepsdk-rulesengine-ios\.git"

getRepo() {
    local extensionName=$1
    local url="repos_$extensionName"
    echo "${!url}"
}

help()
{
   echo ""
   echo "Usage: $0 -n EXTENSION_NAME -v NEW_VERSION -d \"PODSPEC_DEPENDENCY_1, PODSPEC_DEPENDENCY_2\""
   echo ""
   echo -e "    -n\t- Name of the extension getting a version update. \n\t  Example: Edge, Analytics\n"
   echo -e "    -v\t- New version to use for the extension. \n\t  Example: 3.0.2\n"
   echo -e "    -d (optional)\t- Dependency(ies) that require updating in the extension's podspec and Package.swift file. \n\t  Example: -d \"AEPCore 3.7.3\" (update the dependency on AEPCore to version 3.7.3 or newer)\n"
   exit 1 # Exit script after printing help
}

while getopts "n:v:d:" opt
do
   case "$opt" in
      n ) NAME="$OPTARG" ;;
      v ) NEW_VERSION="$OPTARG" ;;
      d ) DEPENDENCIES="$OPTARG" ;;      
      ? ) help ;; # Print help in case parameter is non-existent
   esac
done

# Print help in case parameters are empty
if [ -z "$NAME" ] || [ -z "$NEW_VERSION" ]
then
   echo "********** USAGE ERROR **********"
   echo "Some or all of the parameters are empty. See usage below:";
   help
fi

PODSPEC_FILE=$ROOT_DIR"/AEP"$NAME.podspec
SPM_FILE=$ROOT_DIR/Package.swift

# Begin script in case all parameters are correct
echo ""
echo "$LINE"
echo "Changing version of AEP$NAME to $NEW_VERSION with the following minimum version dependencies: $DEPENDENCIES"
echo "$LINE"

# Replace extension version in podspec
echo "Changing value of 's.version' to '$NEW_VERSION' in '$PODSPEC_FILE'"
sed -i '' -E "/^ *s.version/{s/$VERSION_REGEX/$NEW_VERSION/;}" $PODSPEC_FILE

# Replace dependencies in podspec and Package.swift
if [ "$DEPENDENCIES" != "none" ]; then
    IFS="," 
    dependenciesArray=($(echo "$DEPENDENCIES"))

    IFS=" "
    for dependency in "${dependenciesArray[@]}"; do
        dependencyArray=(${dependency// / })
        dependencyName=${dependencyArray[0]}
        dependencyVersion=${dependencyArray[1]}
        
        echo "Changing value of 's.dependency' for '$dependencyName' to '>= $dependencyVersion' in '$PODSPEC_FILE'"
        sed -i '' -E "/^ *s.dependency +'$dependencyName'/{s/$VERSION_REGEX/$dependencyVersion/;}" $PODSPEC_FILE

        spmRepoUrl=$(getRepo $dependencyName)
        if [ "$spmRepoUrl" != "" ]; then
            echo "Changing value of '.upToNextMajor(from:)' for '$spmRepoUrl' to '$dependencyVersion' in '$SPM_FILE'"
            sed -i '' -E "/$spmRepoUrl\", \.upToNextMajor/{s/$VERSION_REGEX/$dependencyVersion/;}" $SPM_FILE
        fi
    done
fi

# Replace version in Constants file
if [ "$NAME" == "Services" ]; then
    # Nothing, Services has no constants file
    echo "No constants to replace"
elif [ "$NAME" == "Core" ]; then
    # Core needs to update Event Hub and Configuration Constants
    CONSTANTS_FILE=$ROOT_DIR"/AEP$NAME/Sources/configuration/ConfigurationConstants.swift"
    echo "Changing value of 'EXTENSION_VERSION' to '$NEW_VERSION' in '$CONSTANTS_FILE'"
    sed -i '' -E "/^ +static let EXTENSION_VERSION/{s/$VERSION_REGEX/$NEW_VERSION/;}" $CONSTANTS_FILE

    EVENT_HUB_FILE=$ROOT_DIR"/AEP$NAME/Sources/eventhub/EventHubConstants.swift"
    echo "Changing value of 'VERSION_NUMBER' to '$NEW_VERSION' in '$EVENT_HUB_FILE'"
    sed -i '' -E "/^ +static let VERSION_NUMBER/{s/$VERSION_REGEX/$NEW_VERSION/;}" $EVENT_HUB_FILE
else
    CONSTANTS_FILE=$ROOT_DIR"/AEP$NAME/Sources/"$NAME"Constants.swift"
    echo "Changing value of 'EXTENSION_VERSION' to '$NEW_VERSION' in '$CONSTANTS_FILE'"
    sed -i '' -E "/^ +static let EXTENSION_VERSION/{s/$VERSION_REGEX/$NEW_VERSION/;}" $CONSTANTS_FILE
fi

# Replace test version in MobileCoreTests
if [ "$NAME" == "Core" ]; then
    TEST_FILE=$ROOT_DIR"/AEP$NAME/Tests/MobileCoreTests.swift"
    echo "Changing value of 'version' to '$NEW_VERSION' in '$TEST_FILE'"
    sed -i '' -E "/^ +\"version\" : \"/{s/[1-9]+\.[0-9]+\.[0-9]+/$NEW_VERSION/;}" $TEST_FILE
fi

# Replace marketing versions in project.pbxproj
#PROJECT_PBX_FILE=$ROOT_DIR"/AEP$NAME.xcodeproj/project.pbxproj"
PROJECT_PBX_FILE="$ROOT_DIR/AEPCore.xcodeproj/project.pbxproj"
echo "Changing value of 'MARKETING_VERSION' to '$NEW_VERSION' in '$PROJECT_PBX_FILE'"
sed -i '' -E "/^\t+MARKETING_VERSION = /{s/$VERSION_REGEX/$NEW_VERSION/;}" $PROJECT_PBX_FILE
