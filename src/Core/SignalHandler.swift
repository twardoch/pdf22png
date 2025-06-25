import Foundation

// MARK: - Enhanced Signal Handling

class SignalHandler {
    static let shared = SignalHandler()
    private init() {}
    
    private var shouldTerminate = false
    private var cleanupHandlers: [() -> Void] = []
    private let signalQueue = DispatchQueue(label: "signal.handling", qos: .utility)
    
    var isTerminated: Bool {
        return shouldTerminate
    }
    
    func installSignalHandlers() {
        // Handle SIGINT (Ctrl+C)
        signal(SIGINT) { _ in
            SignalHandler.shared.handleGracefulShutdown(signal: "SIGINT")
        }
        
        // Handle SIGTERM (termination request)
        signal(SIGTERM) { _ in
            SignalHandler.shared.handleGracefulShutdown(signal: "SIGTERM")
        }
        
        // Handle SIGHUP (hangup)
        signal(SIGHUP) { _ in
            SignalHandler.shared.handleGracefulShutdown(signal: "SIGHUP")
        }
    }
    
    private func handleGracefulShutdown(signal: String) {
        shouldTerminate = true
        
        fputs("\n📡 Received \(signal), initiating graceful shutdown...\n", stderr)
        fflush(stderr)
        
        // Perform cleanup on a separate queue to avoid deadlocks
        signalQueue.async {
            self.performCleanup()
            
            // Give a brief moment for current operations to finish
            usleep(100_000) // 100ms
            
            fputs("✅ Cleanup complete. Exiting.\n", stderr)
            fflush(stderr)
            exit(1)
        }
    }
    
    private func performCleanup() {
        // Execute registered cleanup handlers
        for handler in cleanupHandlers {
            handler()
        }
        cleanupHandlers.removeAll()
        
        // Clean up resources
        ResourceManager.shared.cleanupAllResources()
    }
    
    func registerCleanupHandler(_ handler: @escaping () -> Void) {
        cleanupHandlers.append(handler)
    }
    
    func checkInterruption() throws {
        if shouldTerminate {
            throw PDF22PNGError.signalInterruption
        }
    }
}