IDENTIFIER = com.catalincezarene.hkd
PLIST = $(IDENTIFIER).plist
APP_SUPPORT_DIR = $(HOME)/Library/Application Support/$(IDENTIFIER)
LAUNCH_AGENTS_DIR = $(HOME)/Library/LaunchAgents

.PHONY: all install uninstall clean

all: hkd $(PLIST)

hkd: Hyperkey.swift Config.swift
	swiftc -parse-as-library -O -o $@ $^
	codesign --force --options runtime --identifier $(IDENTIFIER) --sign - $@

$(PLIST):
	/usr/libexec/PlistBuddy \
		-c "Add :Label string $(IDENTIFIER)" \
		-c "Add :ProgramArguments array" \
		-c "Add :ProgramArguments:0 string '$(APP_SUPPORT_DIR)/hkd'" \
		-c "Add :RunAtLoad bool true" \
		-c "Add :KeepAlive bool true" \
		$@

install: hkd $(PLIST)
	$(MAKE) uninstall
	mkdir -p "$(APP_SUPPORT_DIR)" "$(LAUNCH_AGENTS_DIR)"
	cp hkd "$(APP_SUPPORT_DIR)"
	cp $(PLIST) "$(LAUNCH_AGENTS_DIR)"
	launchctl bootstrap gui/$$(id -u) "$(LAUNCH_AGENTS_DIR)/$(PLIST)"

uninstall:
	-launchctl bootout gui/$$(id -u)/$(IDENTIFIER)
	rm -rf "$(APP_SUPPORT_DIR)"
	rm -f "$(LAUNCH_AGENTS_DIR)/$(PLIST)"

clean:
	rm -f hkd
	rm -f $(PLIST)
