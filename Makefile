# Variables
PROJECT_NAME = AEPCore
AEPCore_TARGET_NAME = AEPCore
AEPSERVIES_TARGET_NAME = AEPServices
AEPLIFECYCLE_TARGET_NAME = AEPLifecycle
AEPIDENTITY_TARGET_NAME = AEPIdentity

# targets
unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing iOS"
	@echo "######################################################################"
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(AEPCore_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8'
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(AEPSERVIES_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8'
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(AEPLIFECYCLE_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8'
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(AEPIDENTITY_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8'
