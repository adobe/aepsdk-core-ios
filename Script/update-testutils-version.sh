#!/bin/bash

# make this script executable from terminal:
# chmod 755 update-testutils-version.sh

set -e # Any subsequent(*) commands which fail will cause the shell script to exit immediately

ROOT_DIR=$(git rev-parse --show-toplevel)
LINE="================================================================================"
VERSION_REGEX="[0-9]+\.[0-9]+\.[0-9]+"
DEPENDENCIES=none

# Determine the platform (macOS or Linux) to adjust the sed command accordingly
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_COMMAND="sed -i '' -E"
else
    SED_COMMAND="sed -i -E"
fi

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

PODSPEC_FILE="$ROOT_DIR/AEP$NAME.podspec"
SPM_FILE="$ROOT_DIR/Package.swift"

# Begin script in case all parameters are correct
echo ""
echo "$LINE"
echo "Changing version of AEP$NAME to $NEW_VERSION with the following minimum version dependencies: $DEPENDENCIES"
echo "$LINE"

# Check if podspec file exists
if [ ! -f "$PODSPEC_FILE" ]; then
  echo "Error: Podspec file '$PODSPEC_FILE' does not exist."
  exit 1
fi

# Update extension version in podspec
echo "Changing value of 's.version' to '$NEW_VERSION' in '$PODSPEC_FILE'"
$SED_COMMAND "/^ *s.version/s/$VERSION_REGEX/$NEW_VERSION/" "$PODSPEC_FILE"

# Update dependencies in podspec and Package.swift
if [ "$DEPENDENCIES" != "none" ]; then
    IFS=","
    dependenciesArray=($(echo "$DEPENDENCIES"))

    IFS=" "
    for dependency in "${dependenciesArray[@]}"; do
        dependencyArray=(${dependency// / })
        dependencyName=${dependencyArray[0]}
        dependencyVersion=${dependencyArray[1]}

        if [ ! -z "$dependencyVersion" ]; then
            echo "Changing value of 's.dependency' for '$dependencyName' to '>= $dependencyVersion' in '$PODSPEC_FILE'"
            $SED_COMMAND "/^ *s.dependency +'$dependencyName'/s/$VERSION_REGEX/$dependencyVersion/" "$PODSPEC_FILE"
        fi
    done
fi
