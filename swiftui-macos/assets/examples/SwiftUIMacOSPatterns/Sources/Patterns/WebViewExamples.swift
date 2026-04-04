#if canImport(WebKit)
  import SwiftUI
  import WebKit

  /// Compile-checked examples for WebKit-for-SwiftUI (macOS Tahoe 26+).
  public enum WebViewExamples {
    /// Minimal `WebView(url:)` usage.
    @available(macOS 26.0, *)
    public struct MinimalWebView: View {
      public var url: URL

      public init(url: URL) {
        self.url = url
      }

      public var body: some View {
        WebView(url: url)
      }
    }

    /// Fallback WKWebView representable for macOS 15+.
    public struct LegacyWebView: NSViewRepresentable {
      public var url: URL

      public init(url: URL) {
        self.url = url
      }

      public func makeNSView(context: Context) -> WKWebView { WKWebView() }

      public func updateNSView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
      }
    }
  }
#endif
