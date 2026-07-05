# recisdb-mirakurun-yakisoba

PX-M1UR 向けに作成した Mirakurun 用の Docker 構成です。

## 概要
- Ubuntu 24.04 / Linux ホストを前提とした構成です。
- `recisdb` を利用する前提で、`arib-b25-stream-test` 関連の処理は含めていません。
- `Dockerfile`、`docker-compose.yml`、`container-init.sh` を適用して利用します。

## 前提
- Docker / Docker Compose が利用できること
- 受信に必要なチューナーデバイスがホスト側に存在すること
- `bcas_keys` を別途用意しておくこと

## 事前準備
1. `bcas_keys` を作成または配置します。
2. 必要に応じて `config/` 配下の設定ファイルを用意します。
3. `docker-compose.yml` の `devices` で、実際のチューナーデバイス名を合わせます。

## 起動方法
```bash
docker compose build
docker compose up -d
```

## 追加メモ
- `px4_drv` をインストールする場合は、以下のコマンドでビルド・起動します。

```bash
sudo docker compose build --no-cache
sudo docker compose up -d
```

- `libyakisoba` と `libsobacas` が `recisdb` と一緒に入ります。
- `config.yml` には、東京地域のチャンネルで GR / BS / CS がすべて含まれる設定例を使います。
- `bcas_keys` は別途作成してください。フォーマットは次のとおりです。

```text
#CardID = f0 f1 f2 f3 f4 f5 f6 f7
#CardKey = 00 01 02 03 04 05 06 07

Key[02][0c] = 00 00 00 00 00 00 00 00
Key[02][0b] = 00 00 00 00 00 00 00 00
Key[03][08] = 00 00 00 00 00 00 00 00
Key[03][09] = 00 00 00 00 00 00 00 00
Key[17][0a] = 00 00 00 00 00 00 00 00
Key[17][0b] = 00 00 00 00 00 00 00 00
Key[1d][00] = 00 00 00 00 00 00 00 00
Key[1d][01] = 00 00 00 00 00 00 00 00
Key[1e][02] = 00 00 00 00 00 00 00 00
Key[1e][01] = 00 00 00 00 00 00 00 00
Key[20][00] = 00 00 00 00 00 00 00 00
Key[20][01] = 00 00 00 00 00 00 00 00
Key[01][02] = 00 00 00 00 00 00 00 00
Key[01][01] = 00 00 00 00 00 00 00 00
```

## 補足
- `docker-compose.yml` では、チューナーデバイスの例をコメントとして整理しています。
- `container-init.sh` は、`pcscd` の起動と Mirakurun 起動を行う初期化スクリプトです。
- 追加のチューナーを有効にする場合は、`devices` セクションに対応するデバイスを追記してください。

