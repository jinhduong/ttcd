import Foundation
import SwiftUI

class AppState: ObservableObject {
    enum MainViewType {
        case stats
        case settings
    }
    
    @Published var activeView: MainViewType = .stats
} 