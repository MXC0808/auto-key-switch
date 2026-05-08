import SwiftUI

/// 应用行视图，处理单个应用的显示和输入法选择（用于菜单栏）
struct AppRowView: View {
    let app: AppInfo
    @EnvironmentObject private var viewModel: InputMethodManager

    var body: some View {
        Menu {
            // 默认输入法选项
            Button(action: {
                viewModel.setInputMethod(for: app, to: nil)
            }) {
                if viewModel.getInputMethod(for: app) == nil {
                    Image(systemName: "checkmark")
                }
                HStack(spacing: 4) {
                    Image(systemName: "circle.dashed")
                    Text("使用默认")
                }
            }

            Divider()

            // 已安装的输入法选项
            ForEach(viewModel.inputMethods, id: \.id) { inputMethod in
                Button(action: {
                    viewModel.setInputMethod(for: app, to: inputMethod.id)
                }) {
                    if viewModel.getInputMethod(for: app) == inputMethod.id {
                        Image(systemName: "checkmark")
                    }
                    HStack(spacing: 4) {
                        if let icon = inputMethod.icon {
                            Image(nsImage: icon)
                        } else {
                            Image(systemName: "keyboard")
                        }
                        Text(inputMethod.name)
                    }
                }
            }
        } label: {
            // 应用行标签内容
            app.icon
            Text(app.name)
            if let name = viewModel.getSelectedInputMethodName(for: app) {
                Text(name)
            }
        }
    }
}
