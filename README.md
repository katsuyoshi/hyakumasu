# 目指せ100マス計算

Line Messaging API を用いた100マス(現在4マス)計算です。

## 動作環境

- ruby 2.7.4p191
- Rails 6.1.4.6

## 準備

### Line Messaging API のchannel作成

ほぼこちらを参考にしました。
下のローカルでの確認も参考にしています。ありがとうございます。

https://qiita.com/TakeshiFukushima/items/aec362407f1ee2f455a9

### ローカルでの確認

Dotenvを使っているので.envファイルに環境変数を設定します。

```
LINE_CHANNEL_ID=xxxxxx
LINE_CHANNEL_SECRET=xxxxx
LINE_CHANNEL_TOKEN=xxxx
```

初期化
```
% bundle install
% rake db:migrate
```

アプリ起動

```
% raila s -b 0.0.0.0
```

Lineからローカル開発環境にアクセスできる様にngrokを起動

```
% ngrok http 3000
ngrok by @inconshreveable                                                             (Ctrl+C to quit)
                                                                                                      
Session Status                online                                                                  
Version                       2.3.40                                                                  
Region                        United States (us)                                                      
Web Interface                 http://127.0.0.1:4040                                                   
Forwarding                    http://1a52-220-209-111-109.ngrok.io -> http://localhost:3000           
Forwarding                    https://1a52-220-209-111-109.ngrok.io -> http://localhost:3000          
```

Forwardingとして表示されるhttpsで表示されるURLを環境変数に登録しRailsアプリを再起動します。

```
SERVER_URL=https://1a52-220-209-111-109.ngrok.io
```

Line Messageing API channelのcallbackにも登録。callbackパスがラインからのcallbackバスとしています。

![](https://i.gyazo.com/5b8adf33fe7baab064f55977e1169269.png)

## 運用

動作確認できたらHerokuなどでアプリを立ち上げます。
Line Messageing API channelのcallbackを運用時のURLに変更します。


