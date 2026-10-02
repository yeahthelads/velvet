import SwiftUI

struct TutorialView: View {
    @ObservedObject var store: NoteStore
    var begin: () -> Void
    var dismiss: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(store.tutorial.text)
                .font(.system(size: 14)).foregroundColor(Color(red: 0.17, green: 0.17, blue: 0.22))
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                if store.tutorial.step == .welcome {
                    Button("Show me", action: begin).buttonStyle(.borderedProminent).tint(.indigo)
                }
                Button(store.tutorial.complete ? "Got it" : "Later", action: dismiss).buttonStyle(.plain)
                    .foregroundColor(.secondary)
            }.font(.system(size: 12))
        }
        .padding(18).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(red: 0.98, green: 0.96, blue: 0.88))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
