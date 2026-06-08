APP_NAME := smove
CONFIG := release
DIST_DIR := dist
APP := $(DIST_DIR)/$(APP_NAME).app
EXECUTABLE := .build/$(CONFIG)/$(APP_NAME)
SIGN_IDENTITY ?= -

.PHONY: build app run install clean

build:
	swift build -c $(CONFIG)

app: build
	rm -rf "$(APP)"
	mkdir -p "$(APP)/Contents/MacOS" "$(APP)/Contents/Resources"
	cp "$(EXECUTABLE)" "$(APP)/Contents/MacOS/$(APP_NAME)"
	cp Info.plist "$(APP)/Contents/Info.plist"
	cp Resources/Shortcuts.json "$(APP)/Contents/Resources/Shortcuts.json"
	cp Resources/smove.icns "$(APP)/Contents/Resources/smove.icns"
	codesign --force --deep --timestamp=none --sign "$(SIGN_IDENTITY)" "$(APP)"
	@printf '%s\n' "Built $(APP)"

run: app
	open "$(APP)"

install: app
	rm -rf "/Applications/$(APP_NAME).app"
	cp -R "$(APP)" "/Applications/$(APP_NAME).app"
	codesign --force --deep --timestamp=none --sign "$(SIGN_IDENTITY)" "/Applications/$(APP_NAME).app"
	@printf '%s\n' "Installed /Applications/$(APP_NAME).app"

clean:
	rm -rf .build dist
