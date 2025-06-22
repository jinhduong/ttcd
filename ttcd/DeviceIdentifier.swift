import Foundation
import IOKit

struct DeviceIdentifier {
    
    /// Provides a unique and stable identifier for the current device.
    /// - Returns: A string containing the hardware UUID, or a new random UUID if it cannot be retrieved.
    static func getUniqueId() -> String {
        // Attempt to get the hardware UUID.
        let platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        
        guard platformExpert > 0 else {
            // Fallback to a random UUID if the hardware UUID can't be accessed.
            return UUID().uuidString
        }
        
        guard let uuid = IORegistryEntryCreateCFProperty(platformExpert, "IOPlatformUUID" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? String else {
            IOObjectRelease(platformExpert)
            return UUID().uuidString
        }
        
        IOObjectRelease(platformExpert)
        
        return uuid
    }
} 