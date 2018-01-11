# このプログラムについて

HTML5版どどんとふの通信の一部をWebSocket化して、サーバー負荷の低減とチャット入力中表示に対応します。

# 実行方法

rubyの実行環境が必要です。
gem、ruby Development Kitのインストールが必要です。

依存ライブラリのインストール
> bundle install

実行
> ruby Main.rb

# 設定ファイル

[config/.config.rb](config/.config.rb)

ログ、サーバー、どどんとふとの連携の設定ができます。

# 備考
どどんとふがMySQLを使用する設定の場合は対象外となります。

# 免責

当プログラムは現状のままで提供されるフリーソフトウェアであり、明示的または暗黙的であるかを問わず、動作およびその他の一切を保証するものではありません。
作者または著作権者は、このプログラムによって、またはこのプログラムを使用することによって発生した一切の請求、損害、その他の義務について何らの責任も負わないものとします。

# ライセンス

MITライセンス

このプログラムは以下のプログラムのコードを使用しています。

* 修正BSDライセンス
* [どどんとふ](http://www.dodontof.com)