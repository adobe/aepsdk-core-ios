# Variables
PROJECT_NAME = AEPCore
AEPCore_TARGET_NAME = AEPCore
AEPSERVIES_TARGET_NAME = AEPServices
AEPLIFECYCLE_TARGET_NAME = AEPLifecycle
AEPIDENTITY_TARGET_NAME = AEPIdentity


SIMULATOR_ARCHIVE_PATH = ./build/ios_simulator.xcarchive/Products/Library/Frameworks/
IOS_ARCHIVE_PATH = ./build/ios.xcarchive/Products/Library/Frameworks/

# targets
unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing iOS"
	@echo "######################################################################"
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(AEPCore_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8'
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(AEPSERVIES_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8'
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(AEPLIFECYCLE_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8'
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(AEPIDENTITY_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8'

archive: 
	xcodebuild archive -scheme AEP-All -archivePath "./build/ios.xcarchive" -sdk iphoneos -destination="iOS" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES 
	xcodebuild archive -scheme AEP-All -archivePath "./build/ios_simulator.xcarchive" -sdk iphonesimulator -destination="iOS Simulator" SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES 
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPSERVIES_TARGET_NAME).framework -framework $(IOS_ARCHIVE_PATH)$(AEPSERVIES_TARGET_NAME).framework -output ./build/$(AEPSERVIES_TARGET_NAME).xcframework
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPCore_TARGET_NAME).framework -framework $(IOS_ARCHIVE_PATH)$(AEPCore_TARGET_NAME).framework -output ./build/$(AEPCore_TARGET_NAME).xcframework
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPLIFECYCLE_TARGET_NAME).framework -framework $(IOS_ARCHIVE_PATH)$(AEPLIFECYCLE_TARGET_NAME).framework -output ./build/$(AEPLIFECYCLE_TARGET_NAME).xcframework
	xcodebuild -create-xcframework -framework $(SIMULATOR_ARCHIVE_PATH)$(AEPIDENTITY_TARGET_NAME).framework -framework $(IOS_ARCHIVE_PATH)$(AEPIDENTITY_TARGET_NAME).framework -output ./build/$(AEPIDENTITY_TARGET_NAME).xcframework

clean:
	rm -rf ./build

format:
	swiftformat . --lint --swiftversion 5.2

lint:
	swiftlint lint


