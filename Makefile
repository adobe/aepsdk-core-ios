# Variables
PROJECT_NAME = AEPCore
AEPCORE_TARGET_NAME = AEPCore
AEPSERVICES_TARGET_NAME = AEPServices
AEPLIFECYCLE_TARGET_NAME = AEPLifecycle
AEPIDENTITY_TARGET_NAME = AEPIdentity
AEPSIGNAL_TARGET_NAME = AEPSignal
AEPINTEGRATION_TEST_TARGET_NAME = AEPIntegrationTests

SIMULATOR_ARCHIVE_PATH = ./build/ios_simulator.xcarchive/Products/Library/Frameworks/
IOS_ARCHIVE_PATH = ./build/ios.xcarchive/Products/Library/Frameworks/

# targets
aep-core-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPCore"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPCORE_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES
aep-services-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPServices"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPSERVICES_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES
aep-lifecycle-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPLifecycle"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPLIFECYCLE_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES
aep-identity-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPIdentity"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPIDENTITY_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES
aep-signal-unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing AEPSignal"
	@echo "######################################################################"
	xcodebuild test -workspace $(PROJECT_NAME).xcworkspace -scheme $(AEPSIGNAL_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES

unit-test-all: aep-core-unit-test aep-services-unit-test aep-lifecycle-unit-test aep-identity-unit-test aep-signal-unit-test

integration-test:
	@echo "######################################################################"
	@echo "### Integration Testing iOS"
	@echo "######################################################################"
	xcodebuild test -project $(PROJECT_NAME).xcworkspace -scheme $(AEPINTEGRATION_TEST_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES

archive:
	xcodebuild archive -workspace AEPCore.xcworkspace -scheme AEP-All -archivePath "./build/ios.xcarchive" -sdk iphoneos -destination="iOS" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
	xcodebuild archive -workspace AEPCore.xcworkspace -scheme AEP-All -archivePath "./build/ios_simulator.xcarchive" -sdk iphonesimulator -destination="iOS Simulator" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPSERVICES_TARGET_NAME).framework -framework $(IOS_ARCHIVE_PATH)$(AEPSERVICES_TARGET_NAME).framework -output ./build/$(AEPSERVICES_TARGET_NAME).xcframework
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPCORE_TARGET_NAME).framework -framework $(IOS_ARCHIVE_PATH)$(AEPCORE_TARGET_NAME).framework -output ./build/$(AEPCORE_TARGET_NAME).xcframework
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPLIFECYCLE_TARGET_NAME).framework -framework $(IOS_ARCHIVE_PATH)$(AEPLIFECYCLE_TARGET_NAME).framework -output ./build/$(AEPLIFECYCLE_TARGET_NAME).xcframework
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPIDENTITY_TARGET_NAME).framework -framework $(IOS_ARCHIVE_PATH)$(AEPIDENTITY_TARGET_NAME).framework -output ./build/$(AEPIDENTITY_TARGET_NAME).xcframework
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPSIGNAL_TARGET_NAME).framework -framework $(IOS_ARCHIVE_PATH)$(AEPSIGNAL_TARGET_NAME).framework -output ./build/$(AEPSIGNAL_TARGET_NAME).xcframework
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)AEPRulesEngine.framework -framework $(IOS_ARCHIVE_PATH)AEPRulesEngine.framework -output ./build/AEPRulesEngine.xcframework

clean:
	rm -rf ./build

format:
	swiftformat . --swiftversion 5.1

lint-autocorrect:
	swiftlint autocorrect

lint:
	swiftlint lint

checkFormat:
	swiftformat . --lint --swiftversion 5.1


loc:
	# use the following brew command to install cloc
	# brew install cloc
	cloc AEPSignal/Sources AEPIdentity/Sources AEPLifecycle/Sources AEPCore/Sources AEPServices/Sources	
