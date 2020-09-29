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

DERIVED_DATA_COVERAGE_PATH = ./build/out/Logs/Test
COVERAGE_REPORT_PATH = ./build/coverageReports

# targets
unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing iOS"
	@echo "######################################################################"
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(AEPCORE_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES
	mkdir -p $(COVERAGE_REPORT_PATH)/$(AEPCORE_TARGET_NAME)
	mv $(DERIVED_DATA_COVERAGE_PATH)/*.xcresult $(COVERAGE_REPORT_PATH)/$(AEPCORE_TARGET_NAME)/
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(AEPSERVICES_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES
	mkdir -p $(COVERAGE_REPORT_PATH)/$(AEPSERVICES_TARGET_NAME)
	mv $(DERIVED_DATA_COVERAGE_PATH)/*.xcresult $(COVERAGE_REPORT_PATH)/$(AEPSERVICES_TARGET_NAME)/
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(AEPLIFECYCLE_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES
	mkdir -p $(COVERAGE_REPORT_PATH)/$(AEPLIFECYCLE_TARGET_NAME)
	mv $(DERIVED_DATA_COVERAGE_PATH)/*.xcresult $(COVERAGE_REPORT_PATH)/$(AEPLIFECYCLE_TARGET_NAME)/
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(AEPIDENTITY_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES
	mkdir -p $(COVERAGE_REPORT_PATH)/$(AEPIDENTITY_TARGET_NAME)
	mv $(DERIVED_DATA_COVERAGE_PATH)/*.xcresult $(COVERAGE_REPORT_PATH)/$(AEPIDENTITY_TARGET_NAME)/
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(AEPSIGNAL_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES
	mkdir -p $(COVERAGE_REPORT_PATH)/$(AEPSIGNAL_TARGET_NAME)
	mv $(DERIVED_DATA_COVERAGE_PATH)/*.xcresult $(COVERAGE_REPORT_PATH)/$(AEPSIGNAL_TARGET_NAME)/

integration-test:
	@echo "######################################################################"
	@echo "### Integration Testing iOS"
	@echo "######################################################################"
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(AEPINTEGRATION_TEST_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8' -derivedDataPath build/out -enableCodeCoverage YES
	mkdir -p $(COVERAGE_REPORT_PATH)/$(AEPINTEGRATION_TEST_TARGET_NAME)
	mv $(DERIVED_DATA_COVERAGE_PATH)/*.xcresult $(COVERAGE_REPORT_PATH)/$(AEPINTEGRATION_TEST_TARGET_NAME)/

archive:
	xcodebuild archive -scheme AEP-All -archivePath "./build/ios.xcarchive" -sdk iphoneos -destination="iOS" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
	xcodebuild archive -scheme AEP-All -archivePath "./build/ios_simulator.xcarchive" -sdk iphonesimulator -destination="iOS Simulator" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPSERVICES_TARGET_NAME).framework -framework $(IOS_ARCHIVE_PATH)$(AEPSERVICES_TARGET_NAME).framework -output ./build/$(AEPSERVICES_TARGET_NAME).xcframework
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPCORE_TARGET_NAME).framework -framework $(IOS_ARCHIVE_PATH)$(AEPCORE_TARGET_NAME).framework -output ./build/$(AEPCORE_TARGET_NAME).xcframework
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPLIFECYCLE_TARGET_NAME).framework -framework $(IOS_ARCHIVE_PATH)$(AEPLIFECYCLE_TARGET_NAME).framework -output ./build/$(AEPLIFECYCLE_TARGET_NAME).xcframework
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPIDENTITY_TARGET_NAME).framework -framework $(IOS_ARCHIVE_PATH)$(AEPIDENTITY_TARGET_NAME).framework -output ./build/$(AEPIDENTITY_TARGET_NAME).xcframework
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPSIGNAL_TARGET_NAME).framework -framework $(IOS_ARCHIVE_PATH)$(AEPSIGNAL_TARGET_NAME).framework -output ./build/$(AEPSIGNAL_TARGET_NAME).xcframework

clean:
	rm -rf ./build

format:
	swiftformat . --swiftversion 5.2

lint-autocorrect:
	swiftlint autocorrect

lint:
	swiftlint lint

checkFormat:
	swiftformat . --lint --swiftversion 5.2
