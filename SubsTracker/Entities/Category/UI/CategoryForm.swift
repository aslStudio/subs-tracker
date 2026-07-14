import SwiftUI

struct CategoryFormView: View {
    @Binding var title: String
    @Binding var color: Color
    
    var body: some View {
        Form {
            Section {
                TextField("Name", text: $title)

                ColorPicker(
                    "Color",
                    selection: $color,
                    supportsOpacity: false
                )
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: 96)
        }
    }
}

private struct CategoryFormViewPreview: View {
    @State private var title = ""
    @State private var color = Color.red
    
    var body: some View {
        CategoryFormView(
            title: $title,
            color: $color
        )
    }
}

#Preview {
    CategoryFormViewPreview()
}
