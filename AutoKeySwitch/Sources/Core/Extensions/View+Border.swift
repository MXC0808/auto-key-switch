import SwiftUI

private struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat {
                switch edge {
                case .top, .bottom, .leading: rect.minX
                case .trailing: rect.maxX - width
                }
            }

            var y: CGFloat {
                switch edge {
                case .top, .leading, .trailing: rect.minY
                case .bottom: rect.maxY - width
                }
            }

            var w: CGFloat {
                switch edge {
                case .top, .bottom: rect.width
                case .leading, .trailing: width
                }
            }

            var h: CGFloat {
                switch edge {
                case .top, .bottom: width
                case .leading, .trailing: rect.height
                }
            }
            path.addPath(Path(CGRect(x: x, y: y, width: w, height: h)))
        }
        return path
    }
}

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}
