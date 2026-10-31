import Foundation
import CoreGraphics

struct SunburstSegment {
    let node: FolderNode
    let parentNode: FolderNode?
    let startAngle: CGFloat
    let endAngle: CGFloat
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let depth: Int
    let isFiles: Bool
    let isCenter: Bool

    init(node: FolderNode, startAngle: CGFloat, endAngle: CGFloat,
         innerRadius: CGFloat, outerRadius: CGFloat, depth: Int,
         isFiles: Bool = false, isCenter: Bool = false, parentNode: FolderNode? = nil) {
        self.node = node
        self.parentNode = parentNode
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.innerRadius = innerRadius
        self.outerRadius = outerRadius
        self.depth = depth
        self.isFiles = isFiles
        self.isCenter = isCenter
    }
}

struct HitTester {
    static func hitTest(point: CGPoint, center: CGPoint, segments: [SunburstSegment]) -> SunburstSegment? {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let dist = sqrt(dx * dx + dy * dy)
        var angle = atan2(dy, dx)
        if angle < 0 { angle += 2 * .pi }

        // Check segments in reverse order (outermost / last-drawn first)
        for seg in segments.reversed() {
            if seg.isCenter {
                if dist <= seg.outerRadius {
                    return seg
                }
            } else {
                if dist >= seg.innerRadius && dist <= seg.outerRadius {
                    if angle >= seg.startAngle && angle <= seg.endAngle {
                        return seg
                    }
                }
            }
        }
        return nil
    }
}
