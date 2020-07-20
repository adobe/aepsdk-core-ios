# Variables
PROJECT_NAME = AEPCore
AEPSERVIES_TARGET_NAME = AEPServices
AEPEVENTHUB_TARGET_NAME = AEPEventHub
AEPLIFECYCLE_TARGET_NAME = AEPLifecycle

# targets
unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing iOS"
	@echo "######################################################################"
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(PROJECT_NAME) -destination 'platform=iOS Simulator,name=iPhone 8'
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(AEPSERVIES_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8'
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(AEPEVENTHUB_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8'
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(AEPLIFECYCLE_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8'
