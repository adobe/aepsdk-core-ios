# Variables
CURR_DIR := ${CURDIR}
PROJECT_NAME = AEPCore
AEPCORE_TARGET_NAME = AEPCore
AEPSERVICES_TARGET_NAME = AEPServices
AEPLIFECYCLE_TARGET_NAME = AEPLifecycle
AEPIDENTITY_TARGET_NAME = AEPIdentity
AEPSIGNAL_TARGET_NAME = AEPSignal
AEPRULESENGINE_TARGET_NAME = AEPRulesEngine
AEPINTEGRATION_TEST_TARGET_NAME = AEPIntegrationTests

SIMULATOR_ARCHIVE_PATH = ./build/ios_simulator.xcarchive/Products/Library/Frameworks/
TVOS_SIMULATOR_ARCHIVE_PATH = ./build/tvos_simulator.xcarchive/Products/Library/Frameworks/
SIMULATOR_ARCHIVE_DSYM_PATH = $(CURR_DIR)/build/ios_simulator.xcarchive/dSYMs/
TVOS_SIMULATOR_ARCHIVE_DSYM_PATH = $(CURR_DIR)/build/tvos_simulator.xcarchive/dSYMs/
IOS_ARCHIVE_PATH = ./build/ios.xcarchive/Products/Library/Frameworks/
TVOS_ARCHIVE_PATH = ./build/tvos.xcarchive/Products/Library/Frameworks/
IOS_ARCHIVE_DSYM_PATH = $(CURR_DIR)/build/ios.xcarchive/dSYMs/
TVOS_ARCHIVE_DSYM_PATH = $(CURR_DIR)/build/tvos.xcarchive/dSYMs/

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'


# Targets - test

aep-core-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPCore"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPCORE_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES
aep-core-tvos-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPCore on tvOS"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPCORE_TARGET_NAME) -destination 'platform=tvOS Simulator,name=Apple TV' -derivedDataPath build/out -enableCodeCoverage YES
aep-services-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPServices"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPSERVICES_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES
aep-services-tvos-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPServices on tvOS"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPSERVICES_TARGET_NAME) -destination 'platform=tvOS Simulator,name=Apple TV' -derivedDataPath build/out -enableCodeCoverage YES
aep-lifecycle-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPLifecycle"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPLIFECYCLE_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES
aep-lifecycle-tvos-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPLifecycle on tvOS"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPLIFECYCLE_TARGET_NAME) -destination 'platform=tvOS Simulator,name=Apple TV' -derivedDataPath build/out -enableCodeCoverage YES
aep-identity-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPIdentity"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPIDENTITY_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES
aep-identity-tvos-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPIdentity on tvOS"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPIDENTITY_TARGET_NAME) -destination 'platform=tvOS Simulator,name=Apple TV' -derivedDataPath build/out -enableCodeCoverage YES
aep-signal-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPSignal"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPSIGNAL_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES
aep-signal-tvos-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPSignal on tvOS"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPSIGNAL_TARGET_NAME) -destination 'platform=tvOS Simulator,name=Apple TV' -derivedDataPath build/out -enableCodeCoverage YES

unit-test-all: aep-core-unit-test aep-core-tvos-unit-test aep-services-unit-test aep-services-tvos-unit-test aep-lifecycle-unit-test aep-lifecycle-tvos-unit-test aep-identity-unit-test aep-identity-tvos-unit-test aep-signal-unit-test aep-signal-tvos-unit-test

integration-test:
	@echo "######################################################################"
	@echo "### Integration Testing iOS"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPINTEGRATION_TEST_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES

integration-tvos-test:
	@echo "######################################################################"
	@echo "### Integration Testing tvOS"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPINTEGRATION_TEST_TARGET_NAME) -destination 'platform=tvOS Simulator,name=Apple TV' -derivedDataPath build/out -enableCodeCoverage YES

pod-install:
	pod install --repo-update

# Targets - archive


archive: pod-install
	xcodebuild archive -workspace AEPCore.xcworkspace -scheme AEP-All -archivePath "./build/ios.xcarchive" -sdk iphoneos -destination="iOS" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
	xcodebuild archive -workspace AEPCore.xcworkspace -scheme AEP-All -archivePath "./build/tvos.xcarchive" -sdk appletvos -destination="tvOS" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
	xcodebuild archive -workspace AEPCore.xcworkspace -scheme AEP-All -archivePath "./build/ios_simulator.xcarchive" -sdk iphonesimulator -destination="iOS Simulator" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
	xcodebuild archive -workspace AEPCore.xcworkspace -scheme AEP-All -archivePath "./build/tvos_simulator.xcarchive" -sdk appletvsimulator -destination="tvOS Simulator" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPSERVICES_TARGET_NAME).framework -debug-symbols $(SIMULATOR_ARCHIVE_DSYM_PATH)$(AEPSERVICES_TARGET_NAME).framework.dSYM \
	-framework $(TVOS_SIMULATOR_ARCHIVE_PATH)$(AEPSERVICES_TARGET_NAME).framework -debug-symbols $(TVOS_SIMULATOR_ARCHIVE_DSYM_PATH)$(AEPSERVICES_TARGET_NAME).framework.dSYM \
	-framework $(IOS_ARCHIVE_PATH)$(AEPSERVICES_TARGET_NAME).framework -debug-symbols $(IOS_ARCHIVE_DSYM_PATH)$(AEPSERVICES_TARGET_NAME).framework.dSYM \
	-framework $(TVOS_ARCHIVE_PATH)$(AEPSERVICES_TARGET_NAME).framework -debug-symbols $(TVOS_ARCHIVE_DSYM_PATH)$(AEPSERVICES_TARGET_NAME).framework.dSYM -output ./build/$(AEPSERVICES_TARGET_NAME).xcframework
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPCORE_TARGET_NAME).framework -debug-symbols $(SIMULATOR_ARCHIVE_DSYM_PATH)$(AEPCORE_TARGET_NAME).framework.dSYM \
	-framework $(TVOS_SIMULATOR_ARCHIVE_PATH)$(AEPCORE_TARGET_NAME).framework -debug-symbols $(TVOS_SIMULATOR_ARCHIVE_DSYM_PATH)$(AEPCORE_TARGET_NAME).framework.dSYM \
	-framework $(IOS_ARCHIVE_PATH)$(AEPCORE_TARGET_NAME).framework -debug-symbols $(IOS_ARCHIVE_DSYM_PATH)$(AEPCORE_TARGET_NAME).framework.dSYM \
	-framework $(TVOS_ARCHIVE_PATH)$(AEPCORE_TARGET_NAME).framework -debug-symbols $(TVOS_ARCHIVE_DSYM_PATH)$(AEPCORE_TARGET_NAME).framework.dSYM -output ./build/$(AEPCORE_TARGET_NAME).xcframework
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPLIFECYCLE_TARGET_NAME).framework -debug-symbols $(SIMULATOR_ARCHIVE_DSYM_PATH)$(AEPLIFECYCLE_TARGET_NAME).framework.dSYM \
	-framework $(TVOS_SIMULATOR_ARCHIVE_PATH)$(AEPLIFECYCLE_TARGET_NAME).framework -debug-symbols $(TVOS_SIMULATOR_ARCHIVE_DSYM_PATH)$(AEPLIFECYCLE_TARGET_NAME).framework.dSYM \
	-framework $(IOS_ARCHIVE_PATH)$(AEPLIFECYCLE_TARGET_NAME).framework -debug-symbols $(IOS_ARCHIVE_DSYM_PATH)$(AEPLIFECYCLE_TARGET_NAME).framework.dSYM \
	-framework $(TVOS_ARCHIVE_PATH)$(AEPLIFECYCLE_TARGET_NAME).framework -debug-symbols $(TVOS_ARCHIVE_DSYM_PATH)$(AEPLIFECYCLE_TARGET_NAME).framework.dSYM -output ./build/$(AEPLIFECYCLE_TARGET_NAME).xcframework
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPIDENTITY_TARGET_NAME).framework -debug-symbols $(SIMULATOR_ARCHIVE_DSYM_PATH)$(AEPIDENTITY_TARGET_NAME).framework.dSYM \
	-framework $(TVOS_SIMULATOR_ARCHIVE_PATH)$(AEPIDENTITY_TARGET_NAME).framework -debug-symbols $(TVOS_SIMULATOR_ARCHIVE_DSYM_PATH)$(AEPIDENTITY_TARGET_NAME).framework.dSYM \
	-framework $(IOS_ARCHIVE_PATH)$(AEPIDENTITY_TARGET_NAME).framework -debug-symbols $(IOS_ARCHIVE_DSYM_PATH)$(AEPIDENTITY_TARGET_NAME).framework.dSYM \
	-framework $(TVOS_ARCHIVE_PATH)$(AEPIDENTITY_TARGET_NAME).framework -debug-symbols $(TVOS_ARCHIVE_DSYM_PATH)$(AEPIDENTITY_TARGET_NAME).framework.dSYM -output ./build/$(AEPIDENTITY_TARGET_NAME).xcframework
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPSIGNAL_TARGET_NAME).framework -debug-symbols $(SIMULATOR_ARCHIVE_DSYM_PATH)$(AEPSIGNAL_TARGET_NAME).framework.dSYM \
	-framework $(TVOS_SIMULATOR_ARCHIVE_PATH)$(AEPSIGNAL_TARGET_NAME).framework -debug-symbols $(TVOS_SIMULATOR_ARCHIVE_DSYM_PATH)$(AEPSIGNAL_TARGET_NAME).framework.dSYM \
	-framework $(IOS_ARCHIVE_PATH)$(AEPSIGNAL_TARGET_NAME).framework -debug-symbols $(IOS_ARCHIVE_DSYM_PATH)$(AEPSIGNAL_TARGET_NAME).framework.dSYM \
	-framework $(TVOS_ARCHIVE_PATH)$(AEPSIGNAL_TARGET_NAME).framework -debug-symbols $(TVOS_ARCHIVE_DSYM_PATH)$(AEPSIGNAL_TARGET_NAME).framework.dSYM -output ./build/$(AEPSIGNAL_TARGET_NAME).xcframework
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPRULESENGINE_TARGET_NAME).framework -debug-symbols $(SIMULATOR_ARCHIVE_DSYM_PATH)$(AEPRULESENGINE_TARGET_NAME).framework.dSYM \
	-framework $(TVOS_SIMULATOR_ARCHIVE_PATH)$(AEPRULESENGINE_TARGET_NAME).framework -debug-symbols $(TVOS_SIMULATOR_ARCHIVE_DSYM_PATH)$(AEPRULESENGINE_TARGET_NAME).framework.dSYM \
	-framework $(IOS_ARCHIVE_PATH)$(AEPRULESENGINE_TARGET_NAME).framework -debug-symbols $(IOS_ARCHIVE_DSYM_PATH)$(AEPRULESENGINE_TARGET_NAME).framework.dSYM \
	-framework $(TVOS_ARCHIVE_PATH)$(AEPRULESENGINE_TARGET_NAME).framework -debug-symbols $(TVOS_ARCHIVE_DSYM_PATH)$(AEPRULESENGINE_TARGET_NAME).framework.dSYM -output ./build/$(AEPRULESENGINE_TARGET_NAME).xcframework

zip:
	cd build && zip -r -X $(AEPCORE_TARGET_NAME).xcframework.zip $(AEPCORE_TARGET_NAME).xcframework/
	cd build && zip -r -X $(AEPSERVICES_TARGET_NAME).xcframework.zip $(AEPSERVICES_TARGET_NAME).xcframework/
	cd build && zip -r -X $(AEPLIFECYCLE_TARGET_NAME).xcframework.zip $(AEPLIFECYCLE_TARGET_NAME).xcframework/
	cd build && zip -r -X $(AEPIDENTITY_TARGET_NAME).xcframework.zip $(AEPIDENTITY_TARGET_NAME).xcframework/
	cd build && zip -r -X $(AEPSIGNAL_TARGET_NAME).xcframework.zip $(AEPSIGNAL_TARGET_NAME).xcframework/
	cd build && zip -r -X $(AEPRULESENGINE_TARGET_NAME).xcframework.zip $(AEPRULESENGINE_TARGET_NAME).xcframework/
	swift package compute-checksum build/$(AEPCORE_TARGET_NAME).xcframework.zip
	swift package compute-checksum build/$(AEPSERVICES_TARGET_NAME).xcframework.zip
	swift package compute-checksum build/$(AEPLIFECYCLE_TARGET_NAME).xcframework.zip
	swift package compute-checksum build/$(AEPIDENTITY_TARGET_NAME).xcframework.zip
	swift package compute-checksum build/$(AEPSIGNAL_TARGET_NAME).xcframework.zip
	swift package compute-checksum build/$(AEPRULESENGINE_TARGET_NAME).xcframework.zip
# Targets - CI steps

clean:
	rm -rf ./build

format:
	swiftformat . --swiftversion 5.1

lint-autocorrect:
	./Pods/SwiftLint/swiftlint autocorrect

lint:
	./Pods/SwiftLint/swiftlint lint

checkFormat:
	swiftformat . --lint --swiftversion 5.1

loc:
	# use the following brew command to install cloc
	# brew install cloc
	cloc AEPSignal/Sources AEPIdentity/Sources AEPLifecycle/Sources AEPCore/Sources AEPServices/Sources	

latest-version:
	(which jq)
	(echo "AEPServices - " && pod spec cat AEPServices | jq '.version' | tr -d '"')
	(echo "AEPCore - " && pod spec cat AEPCore | jq '.version' | tr -d '"')
	(echo "AEPIdentity - " && pod spec cat AEPIdentity | jq '.version' | tr -d '"')
	(echo "AEPLifecycle - " && pod spec cat AEPLifecycle | jq '.version' | tr -d '"')
	(echo "AEPSignal - " && pod spec cat AEPSignal | jq '.version' | tr -d '"')

version-podspec-local:
	(which jq)
	(echo "AEPServices - ${BLUE}$(shell pod ipc spec AEPServices.podspec | jq '.version' | tr -d '"')${NC}")
	(echo "AEPCore - ${BLUE}$(shell pod ipc spec AEPCore.podspec | jq '.version' | tr -d '"')${NC}")
	(echo "AEPIdentity - ${BLUE}$(shell pod ipc spec AEPIdentity.podspec | jq '.version' | tr -d '"')${NC}")
	(echo "AEPLifecycle - ${BLUE}$(shell pod ipc spec AEPLifecycle.podspec | jq '.version' | tr -d '"')${NC}")
	(echo "AEPSignal - ${BLUE}$(shell pod ipc spec AEPSignal.podspec | jq '.version' | tr -d '"')${NC}")
	
podspec-local-dependency-version:
	(which jq)
	(echo "AEPCore:")
	(echo " -AEPService: $(shell pod ipc spec AEPCore.podspec | jq '.dependencies.AEPServices[0]'| tr -d '"')")
	(echo " -AEPRulesEngine: $(shell pod ipc spec AEPCore.podspec | jq '.dependencies.AEPRulesEngine[0]'| tr -d '"')")
	(echo "AEPIdentity:")
	(echo " -AEPCore: $(shell pod ipc spec AEPIdentity.podspec | jq '.dependencies.AEPCore[0]'| tr -d '"')")
	(echo "AEPLifecycle:")
	(echo " -AEPCore: $(shell pod ipc spec AEPLifecycle.podspec | jq '.dependencies.AEPCore[0]'| tr -d '"')")
	(echo "AEPSignal:")
	(echo " -AEPCore: $(shell pod ipc spec AEPSignal.podspec | jq '.dependencies.AEPCore[0]'| tr -d '"')")

version-source-code:
	(echo "AEPCore - ${BLUE}$(shell cat ./AEPCore/Sources/configuration/ConfigurationConstants.swift | egrep '\s*EXTENSION_VERSION\s*=\s*\"(.*)\"' | ruby -e "puts gets.scan(/\"(.*)\"/)[0] " | tr -d '"')${NC}")
	(echo "AEPIdentity - ${BLUE}$(shell cat ./AEPIdentity/Sources/IdentityConstants.swift | egrep '\s*EXTENSION_VERSION\s*=\s*\"(.*)\"' | ruby -e "puts gets.scan(/\"(.*)\"/)[0] " | tr -d '"')${NC}")
	(echo "AEPLifecycle - ${BLUE}$(shell cat ./AEPLifecycle/Sources/LifecycleConstants.swift | egrep '\s*EXTENSION_VERSION\s*=\s*\"(.*)\"' | ruby -e "puts gets.scan(/\"(.*)\"/)[0] " | tr -d '"')${NC}")
	(echo "AEPSignal - ${BLUE}$(shell cat ./AEPSignal/Sources/SignalConstants.swift | egrep '\s*EXTENSION_VERSION\s*=\s*\"(.*)\"' | ruby -e "puts gets.scan(/\"(.*)\"/)[0] " | tr -d '"')${NC}")

test-SPM-integration:
	(sh ./Script/test-SPM.sh)

test-podspec:
	(sh ./Script/test-podspec.sh)

pod-lint:
	(pod lib lint --allow-warnings --verbose --swift-version=5.1)

# make check-version VERSION=3.1.0
check-version:
	(sh ./Script/version.sh $(VERSION))
