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
                .background(WitnessTheme.bgDeep)
                .preferredColorScheme(.dark)
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
                Button(vm.activeInteractionMode == .text ? "Switch to Presence Mode" : "Switch to Text Mode") {
                    vm.toggleInteractionMode()
                }
                .keyboardShortcut("p", modifiers: [.command])
                
                Divider()
                
                Button("Bring Witness Forward") {
                    NSApp.activate(ignoringOtherApps: true)
                    for window in NSApp.windows where window.canBecomeMain {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .keyboardShortcut("w", modifiers: [.command, .shift])
            }
        }
        
        // Menu Bar Companion
        MenuBarExtra("Witness", systemImage: "hexagon") {
            CompactCompanionView(vm: vm)
                .frame(width: 340, height: 260)
        }
        .menuBarExtraStyle(.window)
    }
}
