#!/bin/bash

set -e # Any subsequent(*) commands which fail will cause the shell script to exit immediately

ROOT_DIR=$(git rev-parse --show-toplevel)
LINE="================================================================================"
VERSION_REGEX="[0-9]+\.[0-9]+\.[0-9]+"

# make this script executable from terminal:
# chmod 755 update-versions.sh

# Example for Signal extension
# AEP_.podspec
# _Constants.swift
# s.dependency 'AEPCore', '>= {version}'

# params needed
# 1. extension name
# 2. new version to use
# 3. dependencies and their versions in podspec

help()
{
   echo ""
   echo "Usage: $0 -n EXTENSION_NAME -v NEW_VERSION -d \"PODSPEC_DEPENDENCY_1, PODSPEC_DEPENDENCY_2\""
   echo ""
   echo -e "    -n\t- Name of the extension getting a version update. \n\t  Example: Edge, Analytics\n"
   echo -e "    -v\t- New version to use for the extension. \n\t  Example: 3.0.2\n"
   echo -e "    -d\t- Dependency(ies) that require updating in the extension's podspec file. \n\t  Example: AEPCore 3.7.3 (means add a dependency on AEPCore for version 3.7.3 or newer)\n"
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
if [ -z "$NAME" ] || [ -z "$NEW_VERSION" ] || [ -z "$DEPENDENCIES" ]
then
   echo "********** USAGE ERROR **********"
   echo "Some or all of the parameters are empty.  See usage below:";
   help
fi

PODSPEC_FILE=$ROOT_DIR"/AEP"$NAME.podspec

# Begin script in case all parameters are correct
echo ""
echo "$LINE"
echo "Changing version of AEP$NAME to $NEW_VERSION with the following minimum version dependencies: $DEPENDENCIES"
echo "$LINE"

# Replace extension version in podspec
echo "Changing value of 's.version' to '$NEW_VERSION' in '$PODSPEC_FILE'"
sed -i '' -E "/^ *s.version/{s/$VERSION_REGEX/$NEW_VERSION/;}" $PODSPEC_FILE

# Replace dependencies in podspec
IFS="," 
dependenciesArray=($(echo "$DEPENDENCIES"))

IFS=" "
for dependency in "${dependenciesArray[@]}"; do    
    dependencyArray=(${dependency// / })    
    dependencyName=${dependencyArray[0]}    
    dependencyVersion=${dependencyArray[1]}    
    
    echo "Changing value of 's.dependency' for '$dependencyName' to '>= $dependencyVersion' in '$PODSPEC_FILE'"    
    sed -i '' -E "/^ *s.dependency +'$dependencyName'/{s/$VERSION_REGEX/$dependencyVersion/;}" $PODSPEC_FILE
done

# Replace version in Constants file
CONSTANTS_FILE=$ROOT_DIR"/AEP$NAME/Sources/"$NAME"Constants.swift"
echo "Changing value of 'EXTENSION_VERSION' to '$NEW_VERSION' in '$CONSTANTS_FILE'"
sed -i '' -E "/^ +static let EXTENSION_VERSION/{s/$VERSION_REGEX/$NEW_VERSION/;}" $CONSTANTS_FILE

# Replace marketing versions in project.pbxproj
#PROJECT_PBX_FILE=$ROOT_DIR"/AEP$NAME.xcodeproj/project.pbxproj"
PROJECT_PBX_FILE="$ROOT_DIR/AEPCore.xcodeproj/project.pbxproj"
echo "Changing value of 'MARKETING_VERSION' to '$NEW_VERSION' in '$PROJECT_PBX_FILE'"
sed -i '' -E "/^\t+MARKETING_VERSION = /{s/$VERSION_REGEX/$NEW_VERSION/;}" $PROJECT_PBX_FILE
