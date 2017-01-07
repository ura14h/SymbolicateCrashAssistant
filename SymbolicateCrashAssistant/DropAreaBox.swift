//
//  DropAreaBox.swift
//  SymbolicateCrashAssistant
//
//  Created by Hiroki Ishiura on 2017/01/07.
//  Copyright © 2017 Hiroki Ishiura. All rights reserved.
//

import Cocoa

@objc protocol DropAreaBoxDelegate: NSObjectProtocol {
	func didDropFiles(sender: DropAreaBox, files: [String])
}

/// The class responding to drag and drop of files with specific extensions.
class DropAreaBox: NSBox {

	weak var delegate: DropAreaBoxDelegate?
	var acceptablePathExtensions: [String] = []
	var isEnabled = true
	var isHighlighted = false

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		register(forDraggedTypes: [NSFilenamesPboardType])
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(bounds)

		// Draw a focus ring.
		if isEnabled && isHighlighted {
			NSSetFocusRingStyle(.only)
			NSRectFill(bounds.insetBy(dx: 6, dy: 6))
		}
	}

	override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
		if let dragged = draggedFiles(draggingInfo: sender) {
			// If at least one acceptable file is included, highlight the view.
			let accepted = acceptableFiles(draggedFiles: dragged)
			if accepted.count > 0 {
				isHighlighted = true
				setNeedsDisplay(bounds)
			}
		}

		return .generic
	}

	override func draggingExited(_ sender: NSDraggingInfo?) {
		// Stop highlighting the view.
		isHighlighted = false
		setNeedsDisplay(bounds)
	}

	override func draggingEnded(_ sender: NSDraggingInfo?) {
		// Stop highlighting the view.
		isHighlighted = false
		setNeedsDisplay(bounds)
	}

	override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
		// If at least one acceptable file is included, notify it to the delegate.
		guard let dragged = draggedFiles(draggingInfo: sender) else {
			return false
		}
		let accepted = acceptableFiles(draggedFiles: dragged)
		guard accepted.count > 0 else {
			return false
		}
		delegate?.didDropFiles(sender: self, files: accepted)
		return true
	}

	private func draggedFiles(draggingInfo: NSDraggingInfo) -> [String]? {
		guard isEnabled else {
			return nil
		}

		// Take out files from the dragging pasteboard.
		let pasteboard = draggingInfo.draggingPasteboard()
		guard let types = pasteboard.types else {
			return nil
		}
		guard types.contains(NSFilenamesPboardType) else {
			return nil
		}
		guard let files = pasteboard.propertyList(forType: NSFilenamesPboardType) as? [String] else {
			return nil
		}
		return files
	}

	private func acceptableFiles(draggedFiles: [String]) -> [String] {
		guard isEnabled else {
			return []
		}

		// Extract files matched specified extension from files which is dragging.
		let files = draggedFiles.filter({ (file) -> Bool in
			let pathExtension = NSString(string: file).pathExtension.lowercased()
			return acceptablePathExtensions.contains(pathExtension)
		})
		return files
	}

}
