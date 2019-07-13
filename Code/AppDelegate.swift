import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, SaneNotifications {
    struct Notifications {
        static let yamlsFound = "YamlsFoundNotification"
        static let save       = "AppDelegateSaveNotification"
    }

    @IBOutlet weak var openMenuItem: NSMenuItem!
    @IBOutlet weak var recentMenu: RecentMenu!
    @IBOutlet weak var saveMenuItem: NSMenuItem!
    @IBOutlet weak var saveAtMenuItem: NSMenuItem!
    @IBOutlet weak var revertMenuItem: NSMenuItem!
    
    @objc dynamic var hasChangesToSave: Bool = false {
        didSet {
            saveMenuItem.isEnabled   = self.hasChangesToSave
            revertMenuItem.isEnabled = self.hasChangesToSave
        }
    }
    
    @IBAction func open(_ sender: Any) {
        guard let dirUrl = Dialog.selectDir() else { return }
        openDirUrl(dirUrl)
    }
    
    // all opening of dirs containing yamls should go through this
    func openDirUrl(_ dirUrl: URL) {
        let result = YamlFinder.openUrl(dirUrl)
        if result.success {
            post(Notifications.yamlsFound, object: result)
            hasChangesToSave = false
            saveAtMenuItem.isEnabled = true
            RecentlyOpened.add(dirUrl)
        } else { // no locale files found in dir
            RecentlyOpened.remove(dirUrl)
        }
    }
    
    @IBAction func save(_ sender: Any) {
        post(Notifications.save)
        hasChangesToSave = false
    }

    @IBAction func saveAt(_ sender: Any) {
        guard let dirUrl = Dialog.selectDir(canCreate: true) else { return }
        post(Notifications.save, object: dirUrl)
    }

    @IBAction func revert(_ sender: Any) {
        open(sender) // simply re-open to revert to saved state
    }
    
    @IBAction func clearRecent(_ sender: Any) {
        RecentlyOpened.removeAll()
    }
    
    // MARK: Application lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        recentMenu.setup()
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if hasChangesToSave && !Dialog.ask(
            "There are unsaved changes. Quit anyway?",
            withTextInput: false,
            buttonTitle: "Yes, discard changes!").confirmed {
                return .terminateCancel
        }
        return .terminateNow
    }
}
