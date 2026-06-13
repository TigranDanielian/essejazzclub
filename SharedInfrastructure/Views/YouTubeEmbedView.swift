//
//  YouTubeEmbedView.swift
//  SharedInfrastructure
//

import SwiftUI
import WebKit
import Core

enum YouTubeEmbedLoadState: Equatable {
    case loading
    case loaded
    case failed
}

private enum YouTubeEmbedConfiguration {
    /// YouTube требует HTTPS-origin владельца контента; `about:blank` даёт Error 153.
    static let embedOrigin = EventWebsiteLink.baseURL.absoluteString

    static let userAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    static func watchURL(for videoID: String) -> URL {
        URL(string: "https://www.youtube.com/watch?v=\(videoID)")!
    }

    static func isValidVideoID(_ videoID: String) -> Bool {
        videoID.count == 11 && videoID.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
    }

    /// IFrame Player API + origin сайта клуба.
    static func playerHTML(videoID: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
            <meta name="referrer" content="strict-origin-when-cross-origin">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
                #player { position: absolute; inset: 0; }
            </style>
        </head>
        <body>
            <div id="player"></div>
            <script src="https://www.youtube.com/iframe_api"></script>
            <script>
                var player;
                function onYouTubeIframeAPIReady() {
                    player = new YT.Player('player', {
                        videoId: '\(videoID)',
                        width: '100%',
                        height: '100%',
                        playerVars: {
                            playsinline: 1,
                            rel: 0,
                            modestbranding: 1,
                            controls: 1,
                            fs: 1,
                            origin: '\(embedOrigin)'
                        },
                        events: {
                            onReady: function() {
                                window.webkit.messageHandlers.playerReady.postMessage('ready');
                            },
                            onError: function(event) {
                                window.webkit.messageHandlers.playerError.postMessage(String(event.data));
                            }
                        }
                    });
                }
            </script>
        </body>
        </html>
        """
    }
}

struct YouTubeEmbedPlayerView: View {
    let videoID: String
    var isActive: Bool = true

    @State private var loadState: YouTubeEmbedLoadState = .loading
    @State private var reloadToken = UUID()

    var body: some View {
        ZStack {
            if isActive {
                YouTubeEmbedView(
                    videoID: videoID,
                    reloadToken: reloadToken,
                    isActive: isActive,
                    loadState: $loadState
                )
            }

            switch loadState {
            case .loading:
                ZStack {
                    thumbnailPreview
                    Color.black.opacity(0.35)
                    ProgressView()
                        .tint(Color(uiColor: Colors.text))
                }
                .allowsHitTesting(false)

            case .failed:
                ZStack {
                    thumbnailPreview
                    Color.black.opacity(0.55)
                    VStack(spacing: 12) {
                        Text("Не удалось загрузить видео")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color(uiColor: Colors.secondaryText))
                            .padding(.horizontal, 16)

                        Button {
                            reloadToken = UUID()
                            loadState = .loading
                        } label: {
                            Label("Повторить", systemImage: "arrow.clockwise")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Color(uiColor: Colors.text))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(uiColor: Colors.cardBackground))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)

                        Button {
                            openInYouTube()
                        } label: {
                            Label("Открыть в YouTube", systemImage: "play.rectangle")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(Color(uiColor: Colors.text))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(uiColor: Colors.cardBackground))
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }

            case .loaded:
                EmptyView()
            }
        }
        .onChange(of: isActive) { _, active in
            if active, loadState == .failed {
                reloadToken = UUID()
                loadState = .loading
            }
        }
    }

    private var thumbnailPreview: some View {
        AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(videoID)/hqdefault.jpg")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                Color(uiColor: Colors.altBackground)
            }
        }
        .clipped()
    }

    private func openInYouTube() {
        let webURL = YouTubeEmbedConfiguration.watchURL(for: videoID)
        if let appURL = URL(string: "youtube://watch?v=\(videoID)"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            UIApplication.shared.open(webURL)
        }
    }
}

// MARK: - WKWebView host (ждёт ненулевой layout, как в TabView)

final class YouTubeWebViewHost: UIView {
    let webView: WKWebView
    var onReadyToLoad: (() -> Void)?

    init(webView: WKWebView) {
        self.webView = webView
        super.init(frame: .zero)
        webView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: topAnchor),
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 1, bounds.height > 1, let onReadyToLoad else { return }
        self.onReadyToLoad = nil
        onReadyToLoad()
    }
}

struct YouTubeEmbedView: UIViewRepresentable {
    let videoID: String
    let reloadToken: UUID
    let isActive: Bool
    @Binding var loadState: YouTubeEmbedLoadState

    func makeCoordinator() -> Coordinator {
        Coordinator(loadState: $loadState)
    }

    func makeUIView(context: Context) -> YouTubeWebViewHost {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let contentController = configuration.userContentController
        contentController.add(context.coordinator, name: Coordinator.playerReadyHandler)
        contentController.add(context.coordinator, name: Coordinator.playerErrorHandler)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.customUserAgent = YouTubeEmbedConfiguration.userAgent
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black

        let host = YouTubeWebViewHost(webView: webView)
        context.coordinator.host = host
        context.coordinator.webView = webView
        return host
    }

    static func dismantleUIView(_ uiView: YouTubeWebViewHost, coordinator: Coordinator) {
        let contentController = uiView.webView.configuration.userContentController
        contentController.removeScriptMessageHandler(forName: Coordinator.playerReadyHandler)
        contentController.removeScriptMessageHandler(forName: Coordinator.playerErrorHandler)
    }

    func updateUIView(_ host: YouTubeWebViewHost, context: Context) {
        guard isActive else { return }

        let loadKey = "\(videoID)-\(reloadToken.uuidString)"
        guard context.coordinator.loadKey != loadKey else { return }
        context.coordinator.loadKey = loadKey

        context.coordinator.scheduleLoad(in: host, videoID: videoID)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        static let playerReadyHandler = "playerReady"
        static let playerErrorHandler = "playerError"

        @Binding var loadState: YouTubeEmbedLoadState
        weak var host: YouTubeWebViewHost?
        weak var webView: WKWebView?
        var loadKey: String?
        private var timeoutTask: Task<Void, Never>?
        private var pendingVideoID: String?

        init(loadState: Binding<YouTubeEmbedLoadState>) {
            _loadState = loadState
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            switch message.name {
            case Self.playerReadyHandler:
                cancelTimeout()
                loadState = .loaded
            case Self.playerErrorHandler:
                markFailed()
            default:
                break
            }
        }

        func scheduleLoad(in host: YouTubeWebViewHost, videoID: String) {
            cancelTimeout()

            guard YouTubeEmbedConfiguration.isValidVideoID(videoID) else {
                markFailed()
                return
            }

            pendingVideoID = videoID
            loadState = .loading

            host.onReadyToLoad = { [weak self, weak host] in
                guard let self, let host, let videoID = self.pendingVideoID else { return }
                self.beginLoad(in: host.webView, videoID: videoID)
            }
            host.setNeedsLayout()
            host.layoutIfNeeded()
        }

        func beginLoad(in webView: WKWebView, videoID: String) {
            cancelTimeout()
            loadState = .loading

            webView.loadHTMLString(
                YouTubeEmbedConfiguration.playerHTML(videoID: videoID),
                baseURL: EventWebsiteLink.baseURL
            )
            startTimeout()
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            decisionHandler(.allow)
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                UIApplication.shared.open(url)
            }
            return nil
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            guard !shouldIgnore(error) else { return }
            markFailed()
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            guard !shouldIgnore(error) else { return }
            markFailed()
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            webView.reload()
        }

        private func shouldIgnore(_ error: Error) -> Bool {
            let nsError = error as NSError
            return nsError.code == NSURLErrorCancelled
        }

        private func markFailed() {
            cancelTimeout()
            loadState = .failed
        }

        private func startTimeout() {
            cancelTimeout()
            timeoutTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                guard !Task.isCancelled, loadState == .loading else { return }
                loadState = .failed
            }
        }

        private func cancelTimeout() {
            timeoutTask?.cancel()
            timeoutTask = nil
        }
    }
}
