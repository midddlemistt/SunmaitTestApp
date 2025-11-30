import SwiftUI

@main
struct SunmaitTestAppApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            NewsListView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
        }
    }
}
