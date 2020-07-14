# Variables
PROJECT_NAME = AEPCore
AEPSERVIES_TARGET_NAME = AEPServices

# targets
unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing iOS"
	@echo "######################################################################"
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(PROJECT_NAME) -destination 'platform=iOS Simulator,name=iPhone 8,OS=13.0'
	xcodebuild test -project $(PROJECT_NAME).xcodeproj -scheme $(AEPSERVIES_TARGET_NAME) -destination 'platform=iOS Simulator,name=iPhone 8,OS=13.0'
