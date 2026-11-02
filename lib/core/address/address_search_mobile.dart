import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../widgets/app_loader.dart';
import 'address_result.dart';

/// 이 플랫폼에서 주소 검색 창을 쓸 수 있는가.
const isAddressSearchSupported = true;

/// 카카오(다음) 우편번호 서비스를 전체 화면으로 열고, 사용자가 고른 도로명 주소를 돌려준다.
/// 뒤로 가기로 닫으면 null을 돌려준다.
Future<AddressResult?> searchRoadAddress(BuildContext context) =>
    Navigator.of(context).push<AddressResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _AddressSearchPage(),
      ),
    );

/// 우편번호 서비스를 품은 작은 웹 페이지. 고른 결과는 JavaScript 채널로 앱에 넘어온다.
const _html = '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>html,body,#w{margin:0;padding:0;width:100%;height:100%}</style>
</head>
<body>
<div id="w"></div>
<script src="https://t1.daumcdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js"></script>
<script>
new daum.Postcode({
  oncomplete: function (d) {
    Address.postMessage(JSON.stringify({
      road: d.roadAddress || d.address,
      zone: d.zonecode
    }));
  },
  width: '100%',
  height: '100%'
}).embed(document.getElementById('w'));
</script>
</body>
</html>
''';

class _AddressSearchPage extends StatefulWidget {
  const _AddressSearchPage();

  @override
  State<_AddressSearchPage> createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<_AddressSearchPage> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'Address',
        onMessageReceived: (message) {
          final data = jsonDecode(message.message) as Map<String, dynamic>;
          if (!mounted) return;
          Navigator.of(context).pop(
            AddressResult(
              roadAddress: data['road'] as String? ?? '',
              zonecode: data['zone'] as String? ?? '',
            ),
          );
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (mounted && (error.isForMainFrame ?? true)) {
              setState(() {
                _loading = false;
                _failed = true;
              });
            }
          },
        ),
      )
      ..loadHtmlString(_html, baseUrl: 'https://postcode.map.daum.net/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('주소 검색')),
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_loading) const Center(child: AppLoader()),
            if (_failed) const Center(child: Text('주소 검색을 불러오지 못했습니다')),
          ],
        ),
      ),
    );
  }
}
