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

# CI variables - using values with defaults
IOS_DEVICE_NAME ?= iPhone 16
# If OS version is not specified, uses the first device name match in the list of available simulators
IOS_VERSION ?= 18.5
ifeq ($(strip $(IOS_VERSION)),)
    IOS_DESTINATION = "platform=iOS Simulator,name=$(IOS_DEVICE_NAME)"
else
    IOS_DESTINATION = "platform=iOS Simulator,name=$(IOS_DEVICE_NAME),OS=$(IOS_VERSION)"
endif

TVOS_DEVICE_NAME ?= Apple TV
# If OS version is not specified, uses the first device name match in the list of available simulators
TVOS_VERSION ?= 18.5
ifeq ($(strip $(TVOS_VERSION)),)
	TVOS_DESTINATION = "platform=tvOS Simulator,name=$(TVOS_DEVICE_NAME)"
else
	TVOS_DESTINATION = "platform=tvOS Simulator,name=$(TVOS_DEVICE_NAME),OS=$(TVOS_VERSION)"
endif

# Targets - test

aep-core-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPCore"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPCORE_TARGET_NAME) -destination $(IOS_DESTINATION)  -derivedDataPath build/out -resultBundlePath build/$(AEPCORE_TARGET_NAME)-ios.xcresult -enableCodeCoverage YES
aep-core-tvos-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPCore on tvOS"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPCORE_TARGET_NAME) -destination $(TVOS_DESTINATION)  -derivedDataPath build/out -resultBundlePath build/$(AEPCORE_TARGET_NAME)-tvos.xcresult -enableCodeCoverage YES
aep-services-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPServices"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPSERVICES_TARGET_NAME) -destination $(IOS_DESTINATION) -derivedDataPath build/out -resultBundlePath build/$(AEPSERVICES_TARGET_NAME)-ios.xcresult -enableCodeCoverage YES
aep-services-tvos-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPServices on tvOS"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPSERVICES_TARGET_NAME) -destination $(TVOS_DESTINATION) -derivedDataPath build/out -resultBundlePath build/$(AEPSERVICES_TARGET_NAME)-tvos.xcresult -enableCodeCoverage YES
aep-lifecycle-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPLifecycle"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPLIFECYCLE_TARGET_NAME) -destination $(IOS_DESTINATION) -derivedDataPath build/out -resultBundlePath  build/$(AEPLIFECYCLE_TARGET_NAME)-ios.xcresult -enableCodeCoverage YES
aep-lifecycle-tvos-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPLifecycle on tvOS"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPLIFECYCLE_TARGET_NAME) -destination $(TVOS_DESTINATION) -derivedDataPath build/out -resultBundlePath  build/$(AEPLIFECYCLE_TARGET_NAME)-tvos.xcresult -enableCodeCoverage YES
aep-identity-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPIdentity"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPIDENTITY_TARGET_NAME) -destination $(IOS_DESTINATION) -derivedDataPath build/out -resultBundlePath build/$(AEPIDENTITY_TARGET_NAME)-ios.xcresult -enableCodeCoverage YES
aep-identity-tvos-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPIdentity on tvOS"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPIDENTITY_TARGET_NAME) -destination $(TVOS_DESTINATION) -derivedDataPath build/out -resultBundlePath build/$(AEPIDENTITY_TARGET_NAME)-tvos.xcresult -enableCodeCoverage YES
aep-signal-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPSignal"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPSIGNAL_TARGET_NAME) -destination $(IOS_DESTINATION) -derivedDataPath build/out -resultBundlePath build/$(AEPSIGNAL_TARGET_NAME)-ios.xcresult -enableCodeCoverage YES
aep-signal-tvos-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPSignal on tvOS"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPSIGNAL_TARGET_NAME) -destination $(TVOS_DESTINATION) -derivedDataPath build/out -resultBundlePath build/$(AEPSIGNAL_TARGET_NAME)-tvos.xcresult -enableCodeCoverage YES

unit-test-all: aep-core-unit-test aep-core-tvos-unit-test aep-services-unit-test aep-services-tvos-unit-test aep-lifecycle-unit-test aep-lifecycle-tvos-unit-test aep-identity-unit-test aep-identity-tvos-unit-test aep-signal-unit-test aep-signal-tvos-unit-test

integration-test:
	@echo "######################################################################"
	@echo "### Integration Testing iOS"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPINTEGRATION_TEST_TARGET_NAME) -destination $(IOS_DESTINATION) -derivedDataPath build/out -enableCodeCoverage YES

integration-tvos-test:
	@echo "######################################################################"
	@echo "### Integration Testing tvOS"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPINTEGRATION_TEST_TARGET_NAME) -destination $(TVOS_DESTINATION) -derivedDataPath build/out -enableCodeCoverage YES

archive: _archive

archive-ios: _archive-ios

ci-archive: _archive

ci-archive-ios: _archive-ios

_archive: clean build-ios build-tvos
	./Script/archive.sh create-xcframeworks

_archive-ios: clean build-ios
	./Script/archive.sh create-xcframeworks-ios

build-ios:
	./Script/archive.sh build-ios

build-tvos:
	./Script/archive.sh build-tvos

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

format: lint-autocorrect swift-format

swift-format:
	swiftformat . --swiftversion 5.1

lint-autocorrect:
	swiftlint --fix

lint:
	swiftlint lint

checkFormat:
	swiftformat . --lint --swiftversion 5.1

loc:
	# use the following brew command to install cloc
	# brew install cloc
	cloc AEPSignal/Sources AEPIdentity/Sources AEPLifecycle/Sources AEPCore/Sources AEPServices/Sources	

version-source-code:
	(echo "AEPCore - ${BLUE}$(shell cat ./AEPCore/Sources/configuration/ConfigurationConstants.swift | egrep '\s*EXTENSION_VERSION\s*=\s*\"(.*)\"' | ruby -e "puts gets.scan(/\"(.*)\"/)[0] " | tr -d '"')${NC}")
	(echo "AEPIdentity - ${BLUE}$(shell cat ./AEPIdentity/Sources/IdentityConstants.swift | egrep '\s*EXTENSION_VERSION\s*=\s*\"(.*)\"' | ruby -e "puts gets.scan(/\"(.*)\"/)[0] " | tr -d '"')${NC}")
	(echo "AEPLifecycle - ${BLUE}$(shell cat ./AEPLifecycle/Sources/LifecycleConstants.swift | egrep '\s*EXTENSION_VERSION\s*=\s*\"(.*)\"' | ruby -e "puts gets.scan(/\"(.*)\"/)[0] " | tr -d '"')${NC}")
	(echo "AEPSignal - ${BLUE}$(shell cat ./AEPSignal/Sources/SignalConstants.swift | egrep '\s*EXTENSION_VERSION\s*=\s*\"(.*)\"' | ruby -e "puts gets.scan(/\"(.*)\"/)[0] " | tr -d '"')${NC}")

test-SPM-integration:
	(sh ./Script/test-SPM.sh)

api-check:
	(sh ./Script/api-check.sh  --check --platform ios)
	(sh ./Script/api-check.sh  --check --platform tvos)

api-dump:
	(sh ./Script/api-check.sh  --dump --platform ios)
	(sh ./Script/api-check.sh  --dump --platform tvos)