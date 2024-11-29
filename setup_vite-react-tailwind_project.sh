#!/bin/bash
# プロジェクト名が提供されているか確認します
if [ -z "$1" ]; then
    echo "プロジェクト名を指定してください。"
    exit 1
fi

PROJECT_NAME=$1

# NVM の使用
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
# node.jsの最安定バージョンをインストールから使用状態に変更します
# Node.jsの最安定バージョンをインストールと使用
nvm install --lts
if [ $? -ne 0 ]; then
    echo "Node.jsのインストールに失敗しました。"
    exit 1
fi

nvm use --lts
if [ $? -ne 0 ]; then
    echo "Node.jsの切り替えに失敗しました。"
    exit 1
fi

# 指定されたプロジェクト名でViteプロジェクトを作成します（React + TypeScriptテンプレート）
bun create vite "$PROJECT_NAME" --template react-ts

# プロジェクトディレクトリが正しく作成されたか確認します
if [ ! -d "$PROJECT_NAME" ]; then
    echo "プロジェクトディレクトリの作成に失敗しました。"
    exit 1
fi

# プロジェクトディレクトリに移動します
cd "$PROJECT_NAME"

# 必要なパッケージをインストールします
rm -rf node_modules bun.lockb
bun install
# ViteプロジェクトでReactを使用するための @vitejs/plugin-react パッケージをインストール
bun add @vitejs/plugin-react --dev
# vite-plugin-htmlパッケージをインストール
bun add vite-plugin-html --dev
# Node.jsの型定義を提供する @types/node パッケージをインストール
bun add @types/node --dev

# 他の必要なviteパッケージをインストール
bunx vite

# Tailwind CSSのインストール
bun add -D tailwindcss postcss autoprefixer

# Tailwindの設定ファイルを生成
npx tailwindcss init -p

# デフォルトの不要なファイルを削除します
rm ./src/assets/react.svg ./public/vite.svg ./src/App.css ./src/main.css ./src/index.css

# tailwind.config.jsファイルの設定
cat <<EOF >tailwind.config.js
module.exports = {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
EOF

# Tailwind CSSの設定をCSSファイルに追加
cat <<EOF >./src/css/main.css
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

# package.jsonファイルに内容を書き込みます
cat <<EOF >package.json
{
    "name": "$PROJECT_NAME",
    "private": true,
    "version": "1.0.0",
    "type": "module",
    "scripts": {
        "dev": "vite",
        "build": "vite build",
        "preview": "vite preview",
        "deploy": "vite build && gh-pages -d dist"
    },
    "dependencies": {
        "react": "^18.2.0",
        "react-dom": "^18.2.0"
    },
    "devDependencies": {
        "@types/react": "^18.2.15",
        "@types/react-dom": "^18.2.7",
        "@vitejs/plugin-react": "^4.0.3",
        "eslint": "^8.45.0",
        "eslint-plugin-react": "^7.32.2",
        "eslint-plugin-react-hooks": "^4.6.0",
        "eslint-plugin-react-refresh": "^0.4.3",
        "gh-pages": "^6.1.1",
        "vite": "^4.4.5"
    }
}
EOF

# 必要なディレクトリとファイルを作成します
mkdir ./src/css ./src/assets/fonts ./src/assets/images
touch ./src/css/main.css ./src/pathHelper.ts

# プロジェクトのセットアップが成功したことを通知します
echo "プロジェクト $PROJECT_NAME が正常にセットアップされました。"

# App.tsxファイルに内容を書き込みます
cat <<EOF >./src/pathHelper.ts
export const getImageUrl = (fileName: string, extension: string = "jpg") => {
    return new URL(`./assets/images/${fileName}.${extension}`, import.meta.url)
        .href;
};
EOF

# App.tsxファイルに内容を書き込みます
cat <<EOF >./src/App.tsx
import React from 'react';

function App() {
  return (
    <>
      <p\$ className="">
      </p>
    </>
  );
}

export default App;
EOF

# main.tsxファイルに内容を書き込みます
cat <<EOF >./src/main.tsx
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'
import './css/main.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
)
EOF

# tsconfig.node.jsonファイルに内容を書き込みます
cat <<EOF >tsconfig.node.json
{
  "compilerOptions": {
    "target": "es5", // コードがコンパイルされるJavaScriptのバージョン
    "module": "commonjs",
    "lib": ["es2015", "dom"], // ブラウザのDOMとES2015の機能を利用する
    "types": ["node", "vite", "@vitejs/plugin-react"],
    "composite": true,
    "tsBuildInfoFile": "./node_modules/.tmp/tsconfig.node.tsbuildinfo",
    "skipLibCheck": true,
    "moduleResolution": "node",
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "noEmit": true
  },
  "include": ["vite.config.ts"]
}
EOF

# vite.config.tsファイルに内容を書き込みます
cat <<EOF > vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { OutputAsset, OutputChunk, PreRenderedAsset } from 'rollup';

// GitHub Pages のリポジトリ名に合わせて設定
export default defineConfig({
  base: './',
  plugins: [react()],
  build: {
    rollupOptions: {
      input: 'index.html',
      output: {
        assetFileNames: (assetInfo: PreRenderedAsset) => {
          // 'names' プロパティが存在し、空でないことを確認
          if (assetInfo.names && assetInfo.names.length > 0) {
            // フォントファイルかどうかを判定
            const isFont = assetInfo.names.some(name => /\.(woff2|woff|ttf)$/.test(name));
            if (isFont) {
              return 'assets/fonts/[name][extname]';
            }
          }
          return 'assets/[name][extname]';
        }
      }
    }
  }
});
EOF

# プロジェクト名をindex.htmlに埋め込む処理
INDEX_HTML="./index.html"
if [ -f "$INDEX_HTML" ]; then
    # デフォルトのファビコンリンクを削除
    sed -i '' '/<link rel="icon" type="image\/svg\+xml" href="\/vite.svg" \/>/d' "$INDEX_HTML"

    # <title>タグをプロジェクト名で置き換え
    sed -i '' "s|<title>.*</title>|<title>${PROJECT_NAME}</title>|" "$INDEX_HTML"
    echo "index.htmlが更新されました。"
else
    echo "index.htmlが見つかりません。"
fi

# Gitの初期化とリモートリポジトリの追加
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/Ryusei-Hosokawa/$PROJECT_NAME.git
git branch -M main
git push -u origin main

# gh-pagesのパッケージをインストール
bun add gh-pages --dev

# デプロイ
echo "デプロイを実行します..."
vite deploy

# 開発サーバーを起動し、URLを取得
echo "開発サーバーを起動します..."
> nohup.out
nohup vite > nohup.out 2>&1 &
# 少し待機してサーバーが起動するのを待つ
sleep 2


# URL を取得してブラウザで開く
URL=$(grep -o 'http://localhost:[0-9]*' nohup.out | head -1)
if [ -n "$URL" ]; then
  open "$URL"
else
  echo "サーバーのURLを取得できませんでした。"
fi

code .

echo "プロジェクト $PROJECT_NAME 正常にセットアップされました。"