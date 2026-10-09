APP := build/Snap.app

.PHONY: build install run clean

build:
	mkdir -p $(APP)/Contents/MacOS
	swiftc -O -target arm64-apple-macos13 -o build/Snap-arm64 Sources/*.swift
	swiftc -O -target x86_64-apple-macos13 -o build/Snap-x86_64 Sources/*.swift
	lipo -create build/Snap-arm64 build/Snap-x86_64 -output $(APP)/Contents/MacOS/Snap
	cp Info.plist $(APP)/Contents/Info.plist
	codesign --force --sign - $(APP)

install: build
	rm -rf /Applications/Snap.app
	cp -R $(APP) /Applications/Snap.app

run: install
	open /Applications/Snap.app

clean:
	rm -rf build
