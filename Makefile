# Variables
PROJECT_NAME = AEPCore

# targets
unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing iOS"
	@echo "######################################################################"
	xcodebuild clean test -project $(PROJECT_NAME).xcodeproj -scheme $(PROJECT_NAME) -destination 'platform=iOS Simulator,name=iPhone 11 Pro'
