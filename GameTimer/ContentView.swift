import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "timer")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Game Timer")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
