import SwiftUI
import AVFoundation
import UIKit

/// AVFoundation-backed QR scanner wrapped for SwiftUI. Fires `onScan` exactly
/// once per session — the caller is expected to dismiss the sheet immediately.
struct QRScannerView: UIViewControllerRepresentable {
    let onScan: (String) -> Void
    let onError: (Error) -> Void

    func makeUIViewController(context: Context) -> ScannerVC {
        let vc = ScannerVC()
        vc.onScan = onScan
        vc.onError = onError
        return vc
    }

    func updateUIViewController(_: ScannerVC, context: Context) {}
}

final class ScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onScan: ((String) -> Void)?
    var onError: ((Error) -> Void)?

    // AVCaptureSession is documented as safe to start/stop off-main — that's
    // actually how Apple wants it. nonisolated(unsafe) silences the Sendable
    // warning while keeping the runtime contract correct.
    private nonisolated(unsafe) let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    // AVFoundation calls the delegate on a background queue from Swift 6's
    // perspective even when we asked for .main, so we guard against re-entry
    // with an atomic flag and hop explicitly back to MainActor for state.
    private let didFire = AtomicFlag()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        startSession()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning { session.stopRunning() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func startSession() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self else { return }
            DispatchQueue.main.async {
                guard granted else {
                    self.onError?(NSError(
                        domain: "MCPocket.QR",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Camera access denied."]
                    ))
                    return
                }
                self.configure()
            }
        }
    }

    private func configure() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device)
        else {
            onError?(NSError(
                domain: "MCPocket.QR",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "No camera available."]
            ))
            return
        }
        if session.canAddInput(input) { session.addInput(input) }

        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) { session.addOutput(output) }
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
        }
    }

    nonisolated func metadataOutput(_ output: AVCaptureMetadataOutput,
                                    didOutput metadataObjects: [AVMetadataObject],
                                    from connection: AVCaptureConnection) {
        guard !didFire.testAndSet() else { return }
        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              obj.type == .qr,
              let payload = obj.stringValue
        else { return }
        // Hop back to the main actor — UIKit feedback + SwiftUI closures need it.
        Task { @MainActor [weak self] in
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self?.onScan?(payload)
        }
    }
}

/// Tiny re-entry guard. Sendable because we only mutate via `OSAllocatedUnfairLock`.
private final class AtomicFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var value: Bool = false

    /// Returns true on the first call only; false thereafter. Caller treats
    /// `true` as "I already fired, skip" semantics — see callsite.
    func testAndSet() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if value { return true }
        value = true
        return false
    }
}
