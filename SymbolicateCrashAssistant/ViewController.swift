//
//  ViewController.swift
//  SymbolicateCrashAssistant
//
//  Created by Hiroki Ishiura on 2017/01/07.
//  Copyright © 2017 Hiroki Ishiura. All rights reserved.
//

import Cocoa

/// Main view controller.
class ViewController: NSViewController, DropAreaBoxDelegate {

	@IBOutlet weak var symbolicatecrashPathTextField: NSTextField!
	@IBOutlet weak var appPathTextField: NSTextField!
	@IBOutlet weak var dsymPathTextField: NSTextField!
	@IBOutlet weak var crashPathTextField: NSTextField!
	@IBOutlet weak var dropAreaBox: DropAreaBox!
	@IBOutlet weak var clearButton: NSButton!
	@IBOutlet weak var runButton: NSButton!

	var symbolicator: Symbolicator!

	override func viewDidLoad() {
		super.viewDidLoad()

		// Setup Symbolicator.
		symbolicator = Symbolicator()
		symbolicator.findDeveloperDirPath()
		symbolicator.findSymbolicatecrashPath()

		// Setup DropAreaBox.
		dropAreaBox.delegate = self
		dropAreaBox.acceptablePathExtensions = symbolicator.supportedPathExtensions

		// Setup labels and buttons.
		runButton.title = NSLocalizedString("Run", comment: "")
		updateContents()
	}

	@IBAction func didClickClearButton(_ sender: NSButton) {
		symbolicator.clear()
		updateContents()
	}

	@IBAction func didClickRunButton(_ sender: NSButton) {
		// Disable user interactions.
		clearButton.isEnabled = false
		runButton.isEnabled = false
		runButton.title = NSLocalizedString("Running...", comment: "")

		// Symbolicate.
		symbolicator.run { [weak self] (output) in
			guard let self_ = self else {
				return
			}

			// Enable user interactions.
			self_.clearButton.isEnabled = true
			self_.runButton.isEnabled = true
			self_.runButton.title = NSLocalizedString("Run", comment: "")

			// Save an output of symbolicatecrash as a file.
			guard let content = output else {
				return
			}
			self_.saveFile(content: content)
		}
	}

	func didDropFiles(sender: DropAreaBox, files: [String]) {
		// Apply all dropped files.
		files.forEach { (file) in
			symbolicator.findSuitablePath(file)
		}
		updateContents()
	}

	private func updateContents() {
		// Update lables.
		symbolicatecrashPathTextField.stringValue = symbolicator.symbolicatecrash
		appPathTextField.stringValue = symbolicator.app
		dsymPathTextField.stringValue = symbolicator.dsym
		crashPathTextField.stringValue = symbolicator.crash

		// Update buttons.
		clearButton.isEnabled = symbolicator.canClear()
		runButton.isEnabled = symbolicator.canRun()
	}

	private func saveFile(content: String) {
		// Create a new file name with the original crash log file.
		let baseName = NSString(string: symbolicator.crash).lastPathComponent
		let baseBody = NSString(string: baseName).deletingPathExtension
		let baseExtension = NSString(string: baseName).pathExtension
		let outputFile = "\(baseBody).symbolicated.\(baseExtension)"

		// Show a dialog, write to a file.
		let panel = NSSavePanel()
		panel.title = NSLocalizedString("SymbolicateCrashAssistant", comment: "")
		panel.message = NSLocalizedString("Save Symbolicated Crash Log", comment: "")
		panel.canCreateDirectories = true
		panel.showsTagField = false
		panel.nameFieldStringValue = outputFile
		panel.beginSheetModal(for: self.view.window!) { (result) in
			guard result == NSFileHandlingPanelOKButton else {
				return
			}
			guard let url = panel.url else {
				return
			}
			do {
				try content.write(to: url, atomically: true, encoding: .utf8)
			} catch {
				print("Failed: \(error)")
			}
		}
	}
}

