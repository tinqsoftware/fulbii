import SwiftUI

struct RouteMiniMapView: View {
    let points: [FieldProjectedPoint]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                Path { path in
                    guard points.count > 1 else { return }
                    let first = points[0]
                    path.move(to: CGPoint(
                        x: first.x * geo.size.width,
                        y: (1 - first.y) * geo.size.height
                    ))
                    for point in points.dropFirst() {
                        path.addLine(to: CGPoint(
                            x: point.x * geo.size.width,
                            y: (1 - point.y) * geo.size.height
                        ))
                    }
                }
                .stroke(Color.green, lineWidth: 3)
            }
        }
        .frame(height: 90)
    }
}
