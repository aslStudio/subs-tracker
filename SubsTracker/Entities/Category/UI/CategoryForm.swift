import SwiftUI

struct CategoryFormView: View {
    @Binding var title: String
    @Binding var color: Color
    
    var body: some View {
        Form {
            Section {
                TextField("Название", text: $title)

                ColorPicker(
                    "Цвет",
                    selection: $color,
                    supportsOpacity: false
                )
            }
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
