import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:gap/gap.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:after_layout/after_layout.dart';
import 'package:share_plus/share_plus.dart'; // 공유 기능을 위한 패키지

class NewView extends StatefulWidget {
  const NewView({super.key});

  @override
  State<NewView> createState() => _NewViewState();
}

class _NewViewState extends State<NewView> with AfterLayoutMixin {
  InAppWebViewController? webViewController;

  InAppWebViewSettings settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      iframeAllow: "camera; microphone",
      iframeAllowFullscreen: true);

  late ContextMenu contextMenu;

  PullToRefreshController? pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

  TextEditingController _searchController = TextEditingController(); // TextField 컨트롤러 추가

  OutlineInputBorder outlineBorder = const OutlineInputBorder(
    borderSide: BorderSide(color: Colors.transparent, width: 0.0),
    borderRadius: BorderRadius.all(
      Radius.circular(50.0),
    ),
  );

  bool canGoBack = false;
  bool canGoForward = false;

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {
    _searchController.text = "https://docs.flutter.dev"; // 초기 URL 설정
  }

  @override
  void initState() {
    super.initState();
    contextMenu = ContextMenu(
        menuItems: [
          ContextMenuItem(
              id: 1,
              title: "Special",
              action: () async {
                print("Menu item Special clicked!");
                print(await webViewController?.getSelectedText());
                await webViewController?.clearFocus();
              })
        ],
        settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: false),
        onCreateContextMenu: (hitTestResult) async {
          print("onCreateContextMenu");
          print(hitTestResult.extra);
          print(await webViewController?.getSelectedText());
        },
        onHideContextMenu: () {
          print("onHideContextMenu");
        },
        onContextMenuActionItemClicked: (contextMenuItemClicked) async {
          var id = contextMenuItemClicked.id;
          print(
              "onContextMenuActionItemClicked: $id ${contextMenuItemClicked.title}");
        });

    pullToRefreshController = kIsWeb ||
        ![TargetPlatform.iOS, TargetPlatform.android]
            .contains(defaultTargetPlatform)
        ? null
        : PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (defaultTargetPlatform == TargetPlatform.android) {
          webViewController?.reload();
        } else if (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS) {
          webViewController?.loadUrl(
              urlRequest:
              URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  bool _isValidDomain(String value) {
    final domainPattern = RegExp(r'^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$');
    final noWhitespace = !value.contains(' ');
    return domainPattern.hasMatch(value) && noWhitespace;
  }

  String _normalizeUrl(String url) {
    if (url.endsWith('/')) {
      return url.substring(0, url.length - 1); // URL 끝의 슬래시 제거
    }
    return url;
  }

  Future<void> _handleSubmitted(String value) async {
    final Uri? uri = Uri.tryParse(value);

    if (uri != null && uri.isAbsolute && (uri.scheme == "http" || uri.scheme == "https")) {
      // 유효한 URL이면 웹페이지로 이동
      webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(uri.toString())));
    } else if (_isValidDomain(value)) {
      // 입력된 값이 도메인으로 보일 경우 자동으로 https로 변환
      final domainUrl = 'https://$value';
      webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(domainUrl)));
    } else {
      // 유효한 URL이 아니면 구글 검색
      String searchUrl = "https://www.google.com/search?q=$value";
      webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(searchUrl)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        titleSpacing: 0.0,
        title: SizedBox(
          height: 40.0,
          child: Stack(
            children: <Widget>[
              TextField(
                onTap: () => _searchController.selection = TextSelection(baseOffset: 0, extentOffset: _searchController.text.length),
                onSubmitted: _handleSubmitted,
                keyboardType: TextInputType.url,
                autofocus: false,
                controller: _searchController,  // 주소창과 컨트롤러 연결
                textInputAction: TextInputAction.go,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(
                      left: 45.0, top: 0.0, right: 10.0, bottom: 0.0),
                  filled: true,
                  fillColor: Colors.white,
                  border: outlineBorder,
                  focusedBorder: outlineBorder,
                  enabledBorder: outlineBorder,
                  hintText: "Search for or type a web address",
                  hintStyle:
                  const TextStyle(color: Colors.black54, fontSize: 16.0),
                ),
                style: const TextStyle(color: Colors.black, fontSize: 16.0),
              ),
              IconButton(
                icon: Icon(
                  Icons.ios_share_outlined,
                  size: 20,
                ).opacity(0.7),
                onPressed: () async {
                  if (url.isNotEmpty) {
                    await Share.share('$url');
                  }
                },
              ),
            ],
          ),
        ).padding(left: 12, right: 10),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.arrow_back, color: canGoBack ? Colors.white : Colors.grey, size: 30),
            onPressed: canGoBack
                ? () async {
              if (await webViewController?.canGoBack() ?? false) {
                webViewController?.goBack();
              }
            }
                : null,
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward, color: canGoForward ? Colors.white : Colors.grey, size: 30),
            onPressed: canGoForward
                ? () async {
              if (await webViewController?.canGoForward() ?? false) {
                webViewController?.goForward();
              }
            }
                : null,
          ),
          Gap(10),
        ],
      ),
      body: Column(
        children: [
          InAppWebView(
            initialUrlRequest:
            URLRequest(url: WebUri('https://docs.flutter.dev')),
            initialSettings: settings,
            contextMenu: contextMenu,
            pullToRefreshController: pullToRefreshController,
            onWebViewCreated: (controller) async {
              webViewController = controller;
            },
            onLoadStart: (controller, url) async {
              // 페이지 로드 시작 시 주소 업데이트
              print('페이지 로드 시작: $url');
              setState(() {
                this.url = _normalizeUrl(url.toString()); // 주소창에서 슬래시 제거
                _searchController.text = this.url;  // 주소창 업데이트
              });
            },
            onLoadStop: (controller, url) async {
              pullToRefreshController?.endRefreshing();

              bool canGoBackValue = await (webViewController?.canGoBack() ?? Future.value(false));
              bool canGoForwardValue = await (webViewController?.canGoForward() ?? Future.value(false));

              setState(() {
                this.url = _normalizeUrl(url.toString());  // 슬래시 제거된 URL 설정
                _searchController.text = this.url;  // 주소창 업데이트
                canGoBack = canGoBackValue;
                canGoForward = canGoForwardValue;
              });
            },
            onProgressChanged: (controller, progress) {
              if (progress == 100) {
                pullToRefreshController?.endRefreshing();
              }
              setState(() {
                this.progress = progress / 100;
              });
            },
            onUpdateVisitedHistory: (controller, url, isReload) async {
              // 방문 기록이 업데이트될 때 주소 및 앞으로/뒤로 가기 상태 업데이트
              bool canGoBackValue = await (webViewController?.canGoBack() ?? Future.value(false));
              bool canGoForwardValue = await (webViewController?.canGoForward() ?? Future.value(false));

              setState(() {
                this.url = _normalizeUrl(url.toString()); // 슬래시 제거된 URL 설정
                _searchController.text = this.url;  // 주소창 업데이트
                canGoBack = canGoBackValue;
                canGoForward = canGoForwardValue;
              });
            },
            onConsoleMessage: (controller, consoleMessage) {
              print(consoleMessage);
            },
          ).expanded(),
        ],
      ),
    );
  }
}

main() async {
  return runApp(MaterialApp(
    home: Scaffold(body: NewView()),
  ));
}
