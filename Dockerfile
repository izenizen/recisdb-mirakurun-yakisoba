ARG ARCH=

# --- ステージ1: ビルド環境 (build) ---
FROM ${ARCH}node:24.18.0-bookworm AS build

# libyakisoba / libsobacas のビルドに必要なツールをインストール
RUN apt-get update && apt-get install -y \
    build-essential git libpcsclite-dev pkg-config autoconf automake libtool \
    && rm -rf /var/lib/apt/lists/*

# A. libyakisoba のビルド
WORKDIR /tmp
RUN git clone https://github.com/tsunoda14/libyakisoba.git /tmp/libyakisoba
COPY ./bcas_keys /tmp/libyakisoba/src/bcas_keys
RUN cd /tmp/libyakisoba && autoreconf -i && ./configure && make

# B. libsobacas のビルド
RUN git clone https://github.com/tsunoda14/libsobacas.git /tmp/libsobacas
RUN cd /tmp/libsobacas && autoreconf -i && \
    CPPFLAGS="-I/tmp/libyakisoba/src" LDFLAGS="-L/tmp/libyakisoba/src/.libs" ./configure && \
    make

# C. Mirakurun のビルド（公式最新版のビルドフロー）
WORKDIR /app
# 1. Mirakurunのソースをリポジトリから直接取得
# git clone で取得し、ビルド用の依存関係をインストール
RUN git clone https://github.com/Chinachu/Mirakurun.git . && \
    npm ci --include=dev

# 2. bcas_keys などの必要な設定ファイルは COPY で配置
# (必要な鍵ファイル等はホストからコピーする想定)
COPY ./bcas_keys ./bcas_keys

# 3. ビルド実行
# ソースコードがリポジトリ直下にあるため、npm run build が正しく動作します
RUN npm run build && \
    npm prune --production

# --- ステージ2: 実行環境 (main) ---
FROM ${ARCH}node:24.18.0-bookworm-slim
WORKDIR /app

# 1. 実行に必要なパッケージのインストール
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        make \
        gcc \
        g++ \
        pkg-config \
        pcscd \
        libpcsclite-dev \
        libccid \
        libdvbv5-dev \
        pcsc-tools \
        dvb-tools \
        wget && \
    # 2. recisdb のインストール
    wget https://github.com/kazuki0824/recisdb-rs/releases/download/1.2.4/recisdb_1.2.4-1_amd64.deb && \
    apt-get install -y ./recisdb_1.2.4-1_amd64.deb && \
    rm -f ./recisdb_1.2.4-1_amd64.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 3. ビルド成果物のコピー (.soライブラリ)
COPY --from=build /tmp/libyakisoba/src/.libs/libyakisoba.so* /usr/local/lib/
COPY --from=build /tmp/libsobacas/.libs/libsobacas.so* /usr/local/lib/

# 4. 鍵ファイルの配置と環境変数設定
RUN mkdir -p /usr/local/etc
COPY ./bcas_keys /usr/local/etc/bcas_keys
ENV BCAS_KEYS_FILE=/usr/local/etc/bcas_keys
RUN ldconfig

# 5. Mirakurun本体のコピー
COPY --from=build /app /app

# 6. カスタムした container-init.sh を公式と同じ位置に上書き配置
COPY ./container-init.sh /app/docker/container-init.sh
RUN chmod +x /app/docker/container-init.sh

# 7. 共有ライブラリの強制読み込み環境変数
ENV LD_PRELOAD=/usr/local/lib/libsobacas.so

# 8. 起動設定 (公式と同じパス)
CMD ["./docker/container-init.sh"]
EXPOSE 40772 9229
