//
//  AppDelegate.swift
//  SymbolicateCrashAssistant
//
//  Created by Hiroki Ishiura on 2017/01/07.
//  Copyright © 2017 Hiroki Ishiura. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// No operations.
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// No operations.
	}

	func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
		return true
	}

}

