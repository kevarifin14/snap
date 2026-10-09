APP := build/Snap.app

# Sign with a stable local identity if present (keeps macOS permissions across rebuilds), else ad-hoc.
# Create it with dotfiles/scripts/make-signing-cert.sh
SIGN_ID := $(shell security find-identity -p codesigning | grep -q "Kevin Local Code Signing" && echo "Kevin Local Code Signing" || echo -)

.PHONY: build install run clean icon

build:
	mkdir -p $(APP)/Contents/MacOS
	swiftc -O -target arm64-apple-macos13 -o build/Snap-arm64 Sources/*.swift
	swiftc -O -target x86_64-apple-macos13 -o build/Snap-x86_64 Sources/*.swift
	lipo -create build/Snap-arm64 build/Snap-x86_64 -output $(APP)/Contents/MacOS/Snap
	cp Info.plist $(APP)/Contents/Info.plist
	mkdir -p $(APP)/Contents/Resources
	cp Assets/AppIcon.icns $(APP)/Contents/Resources/
	codesign --force --sign "$(SIGN_ID)" $(APP)

install: build
	rm -rf /Applications/Snap.app
	cp -R $(APP) /Applications/Snap.app

run: install
	open /Applications/Snap.app

clean:
	rm -rf build

# Regenerate Assets/icon.png and Assets/AppIcon.icns from Scripts/make-icon.swift
icon:
	mkdir -p build/AppIcon.iconset
	swift Scripts/make-icon.swift Assets/icon.png 1024
	for sz in 16 32 128 256 512; do \
	  swift Scripts/make-icon.swift build/AppIcon.iconset/icon_$${sz}x$${sz}.png $$sz; \
	  swift Scripts/make-icon.swift build/AppIcon.iconset/icon_$${sz}x$${sz}@2x.png $$((sz * 2)); \
	done
	iconutil -c icns build/AppIcon.iconset -o Assets/AppIcon.icns
