import SwiftUI
import AppKit
import AVDCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    var globalMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        
        // Register Global HotKey monitor: Cmd + Shift + W to bring Witness forward
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains([.command, .shift]) && event.charactersIgnoringModifiers?.lowercased() == "w" {
                Task { @MainActor in
                    NSApp.activate(ignoringOtherApps: true)
                    for window in NSApp.windows where window.canBecomeMain {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
            }
        }
    }
}

@main
struct WitnessApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var vm = AppViewModel()
    
    var body: some Scene {
        // Main Application Window
        WindowGroup("Witness") {
            MainWindowView(vm: vm)
                .background(Color(NSColor.windowBackgroundColor))
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Conversation") {
                    vm.createNewSession()
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
            
            CommandMenu("Witness") {
                Button("Bring Witness Forward") {
                    NSApp.activate(ignoringOtherApps: true)
                    for window in NSApp.windows where window.canBecomeMain {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .keyboardShortcut("w", modifiers: [.command, .shift])
                
                Button("Test Model Connection") {
                    vm.checkConnection()
                }
            }
        }
        
        // Compact Menu Bar Presence
        MenuBarExtra("Witness", systemImage: "circle.hexagongrid.fill") {
            CompactCompanionView(vm: vm)
            
            Divider()
            
            Button("Open Witness Window") {
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows where window.canBecomeMain {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            
            Button("Quit Witness") {
                NSApp.terminate(nil)
            }
        }
        .menuBarExtraStyle(.window)
    }
}
