import SwiftUI
import AppKit

struct SunburstCanvasView: View {
    @EnvironmentObject var appState: AppState
    @State private var canvasSize: CGSize = .zero
    @State private var magnifyStart: CGFloat = 1.0
    @State private var scrollMonitor: Any?

    private let maxRings = 5
    private let minAngleDeg: CGFloat = 1.5
    private let gap: CGFloat = 0.003
    private let bgColor = Color(red: 0.0, green: 0.169, blue: 0.212)
    private let centerFill = NSColor(red: 0.027, green: 0.212, blue: 0.259, alpha: 1)
    private let centerStroke = NSColor(red: 0.345, green: 0.431, blue: 0.459, alpha: 0.3)

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                draw(context: &context, size: size)
            }
            .overlay {
                centerLabel
                    .position(pannedCenter)
                    .allowsHitTesting(false)
            }
            .onChange(of: geo.size) { _, newSize in canvasSize = newSize }
            .onAppear { canvasSize = geo.size }
            .onContinuousHover { phase in
                switch phase {
                case .active(let loc):
                    handleHover(at: loc)
                case .ended:
                    appState.hoveredNode = nil
                    appState.hoveredSegment = nil
                    appState.hoveredIsFiles = false
                }
            }
            .onTapGesture { loc in
                handleClick(at: loc)
            }
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        let newZoom = magnifyStart * value.magnification
                        appState.zoom = min(max(newZoom, 0.3), 4.0)
                        // Snap to 100%
                        if abs(appState.zoom - 1.0) < 0.04 {
                            appState.zoom = 1.0
                        }
                    }
                    .onEnded { _ in
                        magnifyStart = appState.zoom
                    }
            )
            .onAppear {
                magnifyStart = appState.zoom
                scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
                    // Only handle two-finger trackpad scroll (not pinch)
                    guard !event.modifierFlags.contains(.command) else { return event }
                    guard event.phase != [] || event.momentumPhase != [] else { return event }
                    Task { @MainActor in
                        appState.panOffset.width += event.scrollingDeltaX
                        appState.panOffset.height += event.scrollingDeltaY
                    }
                    return event
                }
            }
            .onDisappear {
                if let monitor = scrollMonitor {
                    NSEvent.removeMonitor(monitor)
                    scrollMonitor = nil
                }
            }
            .contextMenu {
                if let seg = appState.hoveredSegment {
                    Button("Open in Finder") {
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: seg.node.url.path)
                    }
                    Button("Copy Path") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(seg.node.url.path, forType: .string)
                    }
                    if !seg.isCenter && !seg.isFiles && !seg.node.children.isEmpty {
                        Button("Drill Into") {
                            appState.drillInto(seg.node)
                        }
                    }
                    Divider()
                    Button("Reveal in Terminal") {
                        let path = seg.node.url.path
                        let script = "tell application \"Terminal\" to do script \"cd \\\"\(path)\\\"\""
                        if let appleScript = NSAppleScript(source: script) {
                            appleScript.executeAndReturnError(nil)
                        }
                    }
                }
            }
        }
        .background(bgColor)
    }

    // MARK: - Center Label

    /// Shows the hovered slice's name and count, or the current folder when nothing is hovered
    @ViewBuilder
    private var centerLabel: some View {
        if let node = appState.currentNode {
            let seg = appState.hoveredSegment.flatMap { $0.isCenter ? nil : $0 }
            let labelNode = seg?.node ?? node
            let name = seg?.isFiles == true ? "Files" : labelNode.name
            let key = seg.map { s in
                s.isFiles ? "files-\((s.parentNode ?? s.node).id)" : s.node.id.uuidString
            } ?? node.id.uuidString

            let isDrilledIn = !appState.navStack.isEmpty
            let nameColor: Color = isDrilledIn ? .white : Color(red: 0.933, green: 0.910, blue: 0.835)
            let countColor: Color = isDrilledIn ? .white.opacity(0.85) : Color(red: 0.165, green: 0.631, blue: 0.596)
            let hintColor: Color = isDrilledIn ? .white.opacity(0.6) : Color(red: 0.345, green: 0.431, blue: 0.459)

            let baseR = min(canvasSize.width, canvasSize.height) / 2 - 20
            let centerR = max(baseR * appState.zoom * 0.15, 20)
            let visible = !appState.isAnimating || appState.animProgress > 0.7

            ZStack {
                VStack(spacing: 2) {
                    Text(name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(nameColor)
                    Text("\(labelNode.total.formatted()) items")
                        .font(.system(size: 11))
                        .foregroundColor(countColor)
                }
                .lineLimit(1)
                .truncationMode(.middle)
                .overlay(alignment: .bottom) {
                    if isDrilledIn && seg == nil {
                        Text("click to go back")
                            .font(.system(size: 9))
                            .foregroundColor(hintColor)
                            .fixedSize()
                            .offset(y: 16)
                    }
                }
                .frame(maxWidth: centerR * 1.7)
                .id(key)
                .transition(.opacity)
            }
            .opacity(visible ? 1 : 0)
            .animation(.easeOut(duration: 0.15), value: key)
            .animation(.easeOut(duration: 0.15), value: visible)
        }
    }

    // MARK: - Drawing

    private func draw(context: inout GraphicsContext, size: CGSize) {
        guard let node = appState.currentNode else { return }

        let cx = size.width / 2 + appState.panOffset.width
        let cy = size.height / 2 + appState.panOffset.height
        let baseR = min(size.width, size.height) / 2 - 20
        let maxR = baseR * appState.zoom
        let centerR = maxR * 0.15
        let ringW = (maxR - centerR) / CGFloat(maxRings)

        let animT = appState.animProgress
        let ringScale = animT
        let globalAlpha = animT

        // Build segments array
        var newSegments: [SunburstSegment] = []

        // Center circle
        let centerPath = Path(ellipseIn: CGRect(
            x: cx - centerR, y: cy - centerR,
            width: centerR * 2, height: centerR * 2
        ))
        // Use the node's Solarized color when drilled in, default base02 at root
        let centerColor: Color
        if appState.navStack.isEmpty {
            centerColor = Color(nsColor: centerFill)
        } else {
            let palette = FolderNode.solarizedAccents
            let base = palette[node.colorIndex % palette.count]
            centerColor = Color(red: base.r, green: base.g, blue: base.b)
        }
        context.fill(centerPath, with: .color(centerColor))
        context.stroke(centerPath, with: .color(Color(nsColor: centerStroke)), lineWidth: 2)

        newSegments.append(SunburstSegment(
            node: node, startAngle: 0, endAngle: .pi * 2,
            innerRadius: 0, outerRadius: centerR, depth: -1, isCenter: true
        ))

        // Draw rings
        let hoveredNode = appState.hoveredNode
        let hlState: String = hoveredNode != nil ? "outside" : "none"

        drawRing(
            context: &context, node: node, depth: 0,
            startAngle: 0, endAngle: .pi * 2,
            cx: cx, cy: cy, centerR: centerR, ringW: ringW,
            ringScale: ringScale, globalAlpha: globalAlpha,
            hlState: hlState, hoveredNode: hoveredNode,
            segments: &newSegments
        )

        // Threshold outlines
        if appState.threshold > 0 && !appState.isAnimating {
            for seg in newSegments {
                if !seg.isCenter && !seg.isFiles && seg.node.total >= appState.threshold {
                    var path = Path()
                    path.addArc(center: CGPoint(x: cx, y: cy), radius: seg.outerRadius,
                                startAngle: .radians(seg.startAngle), endAngle: .radians(seg.endAngle), clockwise: false)
                    path.addArc(center: CGPoint(x: cx, y: cy), radius: seg.innerRadius,
                                startAngle: .radians(seg.endAngle), endAngle: .radians(seg.startAngle), clockwise: true)
                    path.closeSubpath()
                    context.stroke(path, with: .color(.white), lineWidth: 2)
                }
            }
        }

        appState.segments = newSegments
    }

    private func drawRing(
        context: inout GraphicsContext, node: FolderNode, depth: Int,
        startAngle: CGFloat, endAngle: CGFloat,
        cx: CGFloat, cy: CGFloat, centerR: CGFloat, ringW: CGFloat,
        ringScale: CGFloat, globalAlpha: CGFloat, hlState: String,
        hoveredNode: FolderNode?, segments: inout [SunburstSegment]
    ) {
        guard depth < maxRings else { return }

        let targetInner = centerR + CGFloat(depth) * ringW
        let targetOuter = centerR + CGFloat(depth + 1) * ringW
        let innerR = centerR + (targetInner - centerR) * ringScale
        let outerR = centerR + (targetOuter - centerR) * ringScale

        let ringDelay = CGFloat(depth) * 0.12
        let denom = max(1 - ringDelay, 0.001)
        let ringT = max(0, min((globalAlpha - ringDelay) / denom, 1))
        let alpha = ringT

        guard alpha > 0.01 else { return }

        let totalAngle = endAngle - startAngle

        // Build entries: children + files
        struct Entry {
            let node: FolderNode
            let count: Int
            let isFiles: Bool
        }

        var entries: [Entry] = []
        for child in node.children where child.total > 0 {
            entries.append(Entry(node: child, count: child.total, isFiles: false))
        }
        if node.files > 0 {
            let filesNode = FolderNode(name: "\(node.files) files", url: node.url)
            filesNode.files = node.files
            filesNode.total = node.files
            filesNode.colorIndex = node.colorIndex
            entries.append(Entry(node: filesNode, count: node.files, isFiles: true))
        }

        guard !entries.isEmpty else { return }
        entries.sort { $0.count > $1.count }

        let totalCount = entries.reduce(0) { $0 + $1.count }
        guard totalCount > 0 else { return }

        let minAngle = minAngleDeg * .pi / 180

        var boostTotal: CGFloat = 0
        var naturalTotal: Int = 0
        for e in entries {
            let natural = (CGFloat(e.count) / CGFloat(totalCount)) * totalAngle
            if natural < minAngle {
                boostTotal += minAngle
            } else {
                naturalTotal += e.count
            }
        }
        let remainAngle = max(totalAngle - boostTotal, 0)

        var angles: [CGFloat] = entries.map { e in
            let natural = (CGFloat(e.count) / CGFloat(totalCount)) * totalAngle
            if natural < minAngle { return minAngle }
            return naturalTotal > 0 ? (CGFloat(e.count) / CGFloat(naturalTotal)) * remainAngle : minAngle
        }

        // Clamp: if boosted min-angles exceed the parent's range, scale everything down
        let sumAngles = angles.reduce(0, +)
        if sumAngles > totalAngle && sumAngles > 0 {
            let scale = totalAngle / sumAngles
            angles = angles.map { $0 * scale }
        }

        let midAngle = (startAngle + endAngle) / 2
        var angle = startAngle
        let center = CGPoint(x: cx, y: cy)

        for (ei, entry) in entries.enumerated() {
            let segAngle = angles[ei]
            let finalSa = angle + gap / 2
            let finalEa = angle + segAngle - gap / 2
            let sa = midAngle + (finalSa - midAngle) * ringT
            let ea = midAngle + (finalEa - midAngle) * ringT

            guard ea > sa && alpha > 0.01 else {
                angle += segAngle
                continue
            }

            // Determine highlight state
            var entryHl = hlState
            if hlState != "inside" && hlState != "none", let hovered = hoveredNode {
                if entry.node === hovered {
                    entryHl = "inside"
                } else if !entry.isFiles && entry.node.subtreeContains(hovered) {
                    entryHl = "ancestor"
                }
            }

            let isDimmed = entryHl == "outside"
            let isOnPath = entryHl == "ancestor"
            let isHighlighted = entry.node === hoveredNode
            let isInSubtree = entryHl == "inside"

            // Build arc path
            var path = Path()
            path.addArc(center: center, radius: outerR,
                        startAngle: .radians(sa), endAngle: .radians(ea), clockwise: false)
            path.addArc(center: center, radius: innerR,
                        startAngle: .radians(ea), endAngle: .radians(sa), clockwise: true)
            path.closeSubpath()

            // Fill color
            let fillColor = segmentColor(
                node: entry.node, depth: depth, isFiles: entry.isFiles,
                alpha: alpha, isDimmed: isDimmed, isHighlighted: isHighlighted, isOnPath: isOnPath
            )
            context.fill(path, with: .color(fillColor))

            // Stroke
            if isOnPath || isHighlighted {
                context.stroke(path, with: .color(Color.white.opacity(0.6 * alpha)), lineWidth: 2)
            } else {
                let strokeAlpha = isDimmed ? 0.3 * alpha : 0.5 * alpha
                context.stroke(path, with: .color(Color.black.opacity(strokeAlpha)), lineWidth: 1)
            }

            // Store segment with final (non-animated) geometry for hit testing
            segments.append(SunburstSegment(
                node: entry.node, startAngle: finalSa, endAngle: finalEa,
                innerRadius: targetInner, outerRadius: targetOuter,
                depth: depth, isFiles: entry.isFiles,
                parentNode: entry.isFiles ? node : nil
            ))

            // Labels
            if alpha > 0.7 {
                let arcLen = (ea - sa) * ((innerR + outerR) / 2)
                let radialLen = outerR - innerR
                if arcLen > 40 && radialLen > 14 {
                    let labelAngle = (sa + ea) / 2
                    let midR = (innerR + outerR) / 2
                    let lx = cx + cos(labelAngle) * midR
                    let ly = cy + sin(labelAngle) * midR

                    let maxChars = Int(arcLen / 7)
                    var name = entry.node.name
                    if name.count > maxChars && maxChars > 3 {
                        name = String(name.prefix(maxChars - 1)) + "…"
                    }

                    let nameLabel = Text(name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(alpha))
                    let countLabel = Text(entry.count.formatted())
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.7 * alpha))

                    var labelCtx = context
                    labelCtx.translateBy(x: lx, y: ly)
                    var rot = labelAngle
                    if rot > .pi / 2 && rot < .pi * 1.5 { rot += .pi }
                    labelCtx.rotate(by: .radians(rot))

                    labelCtx.draw(nameLabel, at: CGPoint(x: 0, y: -1))
                    labelCtx.draw(countLabel, at: CGPoint(x: 0, y: 11))
                }
            }

            // Recurse children
            if !entry.isFiles && !entry.node.children.isEmpty {
                var childHl = hlState
                if isInSubtree || isHighlighted { childHl = "inside" }
                else if isOnPath { childHl = "outside" }

                drawRing(
                    context: &context, node: entry.node, depth: depth + 1,
                    startAngle: finalSa, endAngle: finalEa,
                    cx: cx, cy: cy, centerR: centerR, ringW: ringW,
                    ringScale: ringScale, globalAlpha: globalAlpha,
                    hlState: childHl, hoveredNode: hoveredNode,
                    segments: &segments
                )
            }

            angle += segAngle
        }
    }

    // MARK: - Colors

    private func segmentColor(
        node: FolderNode, depth: Int, isFiles: Bool,
        alpha: CGFloat, isDimmed: Bool, isHighlighted: Bool, isOnPath: Bool
    ) -> Color {
        let palette = FolderNode.solarizedAccents
        let idx = node.colorIndex % palette.count
        let base = palette[idx]

        // Depth factor: deeper rings get slightly lighter/desaturated
        let depthFade = CGFloat(depth) * 0.08

        if isHighlighted && !isFiles {
            // Brighten on hover
            return Color(
                red: min(base.r + 0.15, 1), green: min(base.g + 0.15, 1), blue: min(base.b + 0.15, 1)
            ).opacity(alpha)
        }
        if isOnPath {
            return Color(
                red: min(base.r + 0.08, 1), green: min(base.g + 0.08, 1), blue: min(base.b + 0.08, 1)
            ).opacity(alpha)
        }

        // Normal or dimmed
        let r = base.r + depthFade * 0.5
        let g = base.g + depthFade * 0.5
        let b = base.b + depthFade * 0.5

        if isDimmed {
            // Desaturate toward gray and darken
            let gray = (r + g + b) / 3
            let dr = r * 0.4 + gray * 0.6
            let dg = g * 0.4 + gray * 0.6
            let db = b * 0.4 + gray * 0.6
            return Color(red: dr * 0.7, green: dg * 0.7, blue: db * 0.7).opacity(alpha * 0.75)
        }

        if isFiles {
            // Desaturated + lighter — clearly distinct from folder segments
            let gray = (r + g + b) / 3
            let fr = r * 0.4 + gray * 0.6 + 0.15
            let fg = g * 0.4 + gray * 0.6 + 0.15
            let fb = b * 0.4 + gray * 0.6 + 0.15
            return Color(red: min(fr, 1), green: min(fg, 1), blue: min(fb, 1)).opacity(alpha * 0.7)
        }

        return Color(red: min(r, 1), green: min(g, 1), blue: min(b, 1)).opacity(alpha)
    }

    // MARK: - Interaction

    private var pannedCenter: CGPoint {
        CGPoint(
            x: canvasSize.width / 2 + appState.panOffset.width,
            y: canvasSize.height / 2 + appState.panOffset.height
        )
    }

    private func handleHover(at point: CGPoint) {
        guard !appState.isAnimating else { return }
        let center = pannedCenter
        if let seg = HitTester.hitTest(point: point, center: center, segments: appState.segments) {
            if seg.isCenter {
                // Keep the center segment so the context menu can target the current folder
                appState.hoveredNode = nil
                appState.hoveredSegment = seg
                appState.hoveredIsFiles = false
                if !appState.navStack.isEmpty {
                    NSCursor.pointingHand.set()
                } else {
                    NSCursor.arrow.set()
                }
            } else {
                // For files, use the parent folder node so the path highlights back to root
                appState.hoveredNode = seg.isFiles ? (seg.parentNode ?? seg.node) : seg.node
                appState.hoveredSegment = seg
                appState.hoveredIsFiles = seg.isFiles
                NSCursor.pointingHand.set()
            }
        } else {
            appState.hoveredNode = nil
            appState.hoveredSegment = nil
            appState.hoveredIsFiles = false
            NSCursor.arrow.set()
        }
    }

    private func handleClick(at point: CGPoint) {
        guard !appState.isAnimating else { return }
        let center = pannedCenter
        guard let seg = HitTester.hitTest(point: point, center: center, segments: appState.segments) else { return }

        if seg.isCenter {
            appState.navigateBack()
            return
        }

        if seg.isFiles { return }

        if !seg.node.children.isEmpty {
            appState.drillInto(seg.node)
        }
    }
}
