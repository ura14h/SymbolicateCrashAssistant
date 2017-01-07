//
//  Symbolicator.swift
//  SymbolicateCrashAssistant
//
//  Created by Hiroki Ishiura on 2017/01/07.
//  Copyright © 2017 Hiroki Ishiura. All rights reserved.
//

import Cocoa

/// The class that converts a raw crash log to symbolicate crash log.
class Symbolicator {

	private enum SupportedFileType: String {
		case xcarchive = "xcarchive"
		case xccrashpoint = "xccrashpoint"
		case app = "app"
		case dsym = "dsym"
		case crash = "crash"
	}

	var symbolicatecrash: String {
		if let path = symbolicatecrashPath {
			return path
		}
		return NSLocalizedString("Install Xcode.", comment: "")
	}

	var app: String {
		if let path = appPath {
			return path
		}
		if crashPath != nil {
			return NSLocalizedString("Detect automatically with using the crash file.", comment: "")
		}
		return NSLocalizedString("Ready to drop xcarchive file or app file.", comment: "")
	}

	var dsym: String {
		if let path = dsymPath {
			return path
		}
		if crashPath != nil {
			return NSLocalizedString("Detect automatically with using the crash file.", comment: "")
		}
		return NSLocalizedString("Ready to drop xcarchive file or dsym file.", comment: "")
	}

	var crash: String {
		if let path = crashPath {
			return path
		}
		return NSLocalizedString("Ready to drop xccrashpoint file or crash file.", comment: "")
	}

	var supportedPathExtensions: [String] {
		if symbolicatecrashPath == nil {
			return []
		}
		return [
			SupportedFileType.xcarchive.rawValue,
			SupportedFileType.xccrashpoint.rawValue,
			SupportedFileType.app.rawValue,
			SupportedFileType.dsym.rawValue,
			SupportedFileType.crash.rawValue,
		]
	}

	private var developerDirPath: String?
	private var symbolicatecrashPath: String?
	private var appPath: String?
	private var dsymPath: String?
	private var crashPath: String?

	init() {
		developerDirPath = nil
		symbolicatecrashPath = nil
		appPath = nil
		dsymPath = nil
		crashPath = nil
	}

	deinit {
		developerDirPath = nil
		symbolicatecrashPath = nil
		appPath = nil
		dsymPath = nil
		crashPath = nil
	}

	func findDeveloperDirPath() {
		// Run `/usr/bin/xcode-select -p`.
		let result = executeCommand(
			command: "/usr/bin/xcode-select",
			arguments: ["-p"])
		guard let stdout = result.stdout else {
			print("Failed: \(result.stderr)")
			return
		}
		guard let line = stdout.components(separatedBy: .newlines).first else {
			print("Failed: no output")
			return
		}
		let path = NSString(string: line).standardizingPath

		// Save "/Applications/Xcode.app/Contents/Developer".
		developerDirPath = path
	}

	func findSymbolicatecrashPath() {
		guard let developerDirPath = self.developerDirPath else {
			return
		}

		// Run `find `dirname `xcode-select -p``/SharedFrameworks -type f -name symbolicatecrash -print`.
		let frameworksDirPath = NSString(string: developerDirPath + "/../SharedFrameworks").standardizingPath
		let result = executeCommand(
			command: "/usr/bin/find",
			arguments: [
				"\(frameworksDirPath)",
				"-type", "f",
				"-name", "symbolicatecrash",
				"-print",
				])
		guard let stdout = result.stdout else {
			print("Failed: \(result.stderr)")
			return
		}
		guard let line = stdout.components(separatedBy: .newlines).first else {
			print("Failed: no output")
			return
		}
		let path = NSString(string: line).standardizingPath

		// Save "/Applications/Xcode.app/Contents/SharedFrameworks/DVTFoundation.framework/Versions/A/Resources/symbolicatecrash".
		symbolicatecrashPath = path
	}

	func findSuitablePath(_ path: String) {
		let pathExtension = NSString(string: path).pathExtension.lowercased()
		switch pathExtension {
		case SupportedFileType.xcarchive.rawValue:
			findXcarchivePath(path)
		case SupportedFileType.xccrashpoint.rawValue:
			findXccrashpointPath(path)
		case SupportedFileType.app.rawValue:
			findAppPath(path)
		case SupportedFileType.dsym.rawValue:
			findDsymPath(path)
		case SupportedFileType.crash.rawValue:
			findCrashPath(path)
		default:
			return
		}
	}

	func findXcarchivePath(_ path: String) {
		// find .app file.
		do {
			// Run `find Products -type d -name "*.app" -print`.
			let result = executeCommand(
				command: "/usr/bin/find",
				arguments: [
					"\(path)/Products",
					"-type", "d",
					"-name", "*.app",
					"-print",
					])
			guard let stdout = result.stdout else {
				print("Failed: \(result.stderr)")
				return
			}
			guard let line = stdout.components(separatedBy: .newlines).first else {
				print("Failed: no output")
				return
			}
			let path = NSString(string: line).standardizingPath

			// Save "($path)/Products/Applications/???.app".
			findAppPath(path)
		}

		// find .dsym file.
		do {
			// Run `find dSYMs -type d -name "*.app.dSYM" -print`.
			let result = executeCommand(
				command: "/usr/bin/find",
				arguments: [
					"\(path)/dSYMs",
					"-type", "d",
					"-name", "*.app.dSYM",
					"-print",
					])
			guard let stdout = result.stdout else {
				print("Failed: \(result.stderr)")
				return
			}
			guard let line = stdout.components(separatedBy: .newlines).first else {
				print("Failed: no output")
				return
			}
			let path = NSString(string: line).standardizingPath

			// Save "($path)/dSYMs/???.app.dSYM".
			findDsymPath(path)
		}
	}

	func findXccrashpointPath(_ path: String) {
		// find .crash file.
		do {
			// Run `find DistributionInfos -type f -name "*.crash" -print`.
			let result = executeCommand(
				command: "/usr/bin/find",
				arguments: [
					"\(path)/DistributionInfos",
					"-type", "f",
					"-name", "*.crash",
					"-print",
					])
			guard let stdout = result.stdout else {
				print("Failed: \(result.stderr)")
				return
			}
			guard let line = stdout.components(separatedBy: .newlines).first else {
				print("Failed: no output")
				return
			}
			let path = NSString(string: line).standardizingPath

			// Save "($path)/DistributionInfos/all/Logs/???.crash".
			findCrashPath(path)
		}
	}

	func findAppPath(_ path: String) {
		appPath = path
	}

	func findDsymPath(_ path: String) {
		dsymPath = path
	}

	func findCrashPath(_ path: String) {
		crashPath = path
	}

	func canClear() -> Bool {
		if appPath == nil && dsymPath == nil && crashPath == nil {
			return false
		}
		return true
	}

	func clear() {
		appPath = nil
		dsymPath = nil
		crashPath = nil
	}

	func canRun() -> Bool {
		if symbolicatecrashPath == nil || crashPath == nil {
			return false
		}
		return true
	}

	func run(completion: @escaping (_ output: String?) -> Void) {
		// Prepare command line parameters.
		guard let symbolicatecrashPath = self.symbolicatecrashPath else {
			completion(nil)
			return
		}
		var environment = [String: String]()
		if let developerDirPath = self.developerDirPath {
			environment["DEVELOPER_DIR"] = developerDirPath
		}
		var arguments = [String]()
		if let dsymPath = self.dsymPath {
			arguments.append("--dsym=\"\(dsymPath)\"")
		}
		if let crashPath = self.crashPath {
			arguments.append(crashPath)
		}
		if let appPath = self.appPath {
			arguments.append(appPath)
		}

		DispatchQueue.global().async { [weak self] in
			guard let self_ = self else {
				return
			}

			// Run `symbolicatecrash`.
			let result = self_.executeCommand(
				command: symbolicatecrashPath,
				arguments: arguments,
				environment: environment)

			// Call the completion handler.
			DispatchQueue.main.async {
				guard let stdout = result.stdout else {
					print("Failed: \(result.stderr)")
					completion(nil)
					return
				}
				if let stderr = result.stderr, stderr != "" {
					print("Warning: \(stderr)")
				}
				completion(stdout)
			}
		}
	}

	private func executeCommand(command: String, arguments: [String]? = nil, environment: [String: String]? = nil) -> (stdout: String?, stderr: String?) {
		// Prepare task parameters.
		let task = Process()
		task.launchPath = command
		if arguments != nil {
			task.arguments = arguments
		}
		if environment != nil {
			task.environment = environment
		}
		let stdoutPipe = Pipe()
		task.standardOutput = stdoutPipe
		let stderrPipe = Pipe()
		task.standardError = stderrPipe

		// Run the task.
		task.launch()

		// Take a result from stdout and stderr.
		let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
		let stdout = String(data: stdoutData, encoding: .utf8)
		let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
		let stderr = String(data: stderrData, encoding: .utf8)

		if task.terminationStatus != 0 {
			print("Failed: terminationStatus=\(task.terminationStatus)")
		}
		return (stdout: stdout, stderr: stderr)
	}

}
