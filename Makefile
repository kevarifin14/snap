APP := build/Snap.app

# Apple Development: Kevin Arifin (9D2HDH9PJG), team 2YE6RDKXDW, on Winstain.
override SIGN_ID := A204907BEC17B7A8707D0A3257B34DE48769AAA8

.PHONY: build install run clean icon

build:
	@security find-identity -v -p codesigning | grep -Eq '^[[:space:]]*[0-9]+\) $(SIGN_ID) "Apple Development:' || \
		{ echo 'Snap needs the pinned Apple Development identity on Winstain.' >&2; exit 1; }
	mkdir -p $(APP)/Contents/MacOS
	swiftc -O -target arm64-apple-macos13 -o build/Snap-arm64 Sources/*.swift
	swiftc -O -target x86_64-apple-macos13 -o build/Snap-x86_64 Sources/*.swift
	lipo -create build/Snap-arm64 build/Snap-x86_64 -output $(APP)/Contents/MacOS/Snap
	cp Info.plist $(APP)/Contents/Info.plist
	mkdir -p $(APP)/Contents/Resources
	cp Assets/AppIcon.icns $(APP)/Contents/Resources/
	codesign --force --sign "$(SIGN_ID)" --timestamp=none --options runtime $(APP)
	codesign --verify --strict $(APP)

install:
	/bin/bash Scripts/install.sh "$(APP)"

run: build
	$(MAKE) install
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
