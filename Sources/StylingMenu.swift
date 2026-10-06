import AppKit

extension AppDelegate {
    func makeStylingMenu() -> NSMenu {
        let menu = NSMenu(); menu.autoenablesItems = false
        for cosmetic in Cosmetic.allCases.sorted(by: { $0.title < $1.title }) {
            let owned = character.styling.purchased.contains(cosmetic)
            let available = character.styling.available.contains(cosmetic)
            let title = cosmetic.title + (owned ? "" : (available ? " · buy for \(cosmetic.price) claps" : " · \(cosmetic.requirement)"))
            let entry = item(title, #selector(selectCosmetic(_:))); entry.representedObject = cosmetic.rawValue
            entry.isEnabled = character.canStyle && (owned || available && character.danceProgress.clapBalance >= cosmetic.price)
            entry.state = character.styling.worn.contains(cosmetic) ? .on : .off
            entry.toolTip = owned ? "An- und Ablegen kostet nichts." : "Freischalten macht das Item kaufbar. Der Kauf kostet \(cosmetic.price) Claps."
            menu.addItem(entry)
        }
        menu.addItem(.separator())
        let balance = NSMenuItem(title: "\(character.danceProgress.clapBalance) claps", action: nil, keyEquivalent: "")
        balance.isEnabled = false; menu.addItem(balance)
        return menu
    }
    @objc func selectCosmetic(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String, let item = Cosmetic(rawValue: id) else { return }
        if character.selectStyle(item) { store.flush(); rebuildMenu() }
    }
}
