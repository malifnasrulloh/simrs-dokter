#!/usr/bin/env bash
set -eo pipefail

# ==============================================================================
# E-Dokter SIMRS Mobile Release Publisher
# Builds signed release APK and publishes directly to Backend-Dokter server
# ==============================================================================

CONFIG_FILE="${1:-config-dev.json}"
RELEASE_NOTES="${2:-Pembaruan otomatis rilis mobile E-Dokter SIMRS.}"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Error: Config file '$CONFIG_FILE' not found!"
  exit 1
fi

echo "=================================================================="
echo "🚀 E-DOKTER MOBILE RELEASE PUBLISHER"
echo "=================================================================="
echo "📋 Configuration : $CONFIG_FILE"

# Extract configuration values
BASE_URL=$(jq -r '.BASE_URL' "$CONFIG_FILE")
APP_VERSION=$(jq -r '.APP_VERSION' "$CONFIG_FILE")
APP_NAME=$(jq -r '.APP_NAME' "$CONFIG_FILE")
USER_AGENT=$(jq -r '.USER_AGENT // empty' "$CONFIG_FILE")
WAF_HEADER=$(jq -r '.WAF_CUSTOM_HEADER // empty' "$CONFIG_FILE")
WAF_VALUE=$(jq -r '.WAF_CUSTOM_VALUE // empty' "$CONFIG_FILE")

# Build optional WAF bypass arguments for curl
CURL_EXTRA_ARGS=()
if [ -n "$USER_AGENT" ]; then
  CURL_EXTRA_ARGS+=(-A "$USER_AGENT")
fi
if [ -n "$WAF_HEADER" ] && [ -n "$WAF_VALUE" ]; then
  CURL_EXTRA_ARGS+=(-H "$WAF_HEADER: $WAF_VALUE")
fi

# Extract version code from pubspec.yaml
VERSION_LINE=$(grep "^version:" pubspec.yaml | head -n 1)
VERSION_RAW=$(echo "$VERSION_LINE" | awk '{print $2}')
VERSION_NAME=$(echo "$VERSION_RAW" | cut -d'+' -f1)
VERSION_CODE=$(echo "$VERSION_RAW" | cut -d'+' -f2)

if [ -z "$VERSION_CODE" ] || [ "$VERSION_CODE" = "$VERSION_RAW" ]; then
  VERSION_CODE="1"
fi

echo "📱 Target App    : $APP_NAME"
echo "📦 Version       : v$VERSION_NAME (Code: $VERSION_CODE)"
echo "🌐 Backend API   : $BASE_URL"
echo "------------------------------------------------------------------"

# 1. Build release APK (Using Shorebird if available so it accepts over-the-air patches)
SHOREBIRD_BIN="/home/user/.shorebird/bin/shorebird"
if command -v shorebird >/dev/null 2>&1; then
  SHOREBIRD_CMD="shorebird"
elif [ -f "$SHOREBIRD_BIN" ]; then
  SHOREBIRD_CMD="$SHOREBIRD_BIN"
else
  SHOREBIRD_CMD=""
fi

if [ -n "$SHOREBIRD_CMD" ]; then
  echo "🐦 Building Release APK with Shorebird ($SHOREBIRD_CMD)..."
  echo "   (This registers the release on Shorebird so doctors can receive instant OTA patches)"
  "$SHOREBIRD_CMD" release android --artifact=apk --dart-define-from-file="$CONFIG_FILE"
else
  echo "🔨 Building Release APK with standard Flutter..."
  flutter build apk --release --dart-define-from-file="$CONFIG_FILE"
fi

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK_PATH" ]; then
  echo "❌ Error: APK build failed! File not found at $APK_PATH"
  exit 1
fi

FILE_SIZE_MB=$(du -m "$APK_PATH" | cut -f1)
echo "✅ APK built successfully ($FILE_SIZE_MB MB)"

# 2. Login to Backend-Dokter to get Admin JWT Token
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASS="${ADMIN_PASS:-spv}"

echo "🔐 Authenticating with backend as admin ($ADMIN_USER)..."
LOGIN_RES=$(curl -s -k -m 30 "${CURL_EXTRA_ARGS[@]}" -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\": \"$ADMIN_USER\", \"password\": \"$ADMIN_PASS\"}")

TOKEN=$(echo "$LOGIN_RES" | jq -r '.token // empty' 2>/dev/null)
if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "❌ Authentication failed! Response from server:"
  echo "$LOGIN_RES"
  echo "💡 If HTML or 502 Bad Gateway, verify your backend service is running and accessible."
  exit 1
fi
echo "✅ Authenticated successfully!"

# 3. Upload and Publish Release
echo "📤 Uploading APK to Backend-Dokter ($BASE_URL/setting/app-upload)..."
UPLOAD_RES=$(curl -k --progress-bar "${CURL_EXTRA_ARGS[@]}" -X POST "$BASE_URL/setting/app-upload" \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@$APK_PATH;type=application/vnd.android.package-archive" \
  -F "version_name=$VERSION_NAME" \
  -F "version_code=$VERSION_CODE" \
  -F "min_supported_version=$VERSION_NAME" \
  -F "release_notes=$RELEASE_NOTES")

SUCCESS=$(echo "$UPLOAD_RES" | jq -r '.success // empty')
if [ "$SUCCESS" != "true" ]; then
  echo "❌ Failed to upload and publish release! Response:"
  echo "$UPLOAD_RES"
  exit 1
fi

SHA256=$(echo "$UPLOAD_RES" | jq -r '.data.sha256_checksum // empty')
DOWNLOAD_URL=$(echo "$UPLOAD_RES" | jq -r '.data.download_url // empty')

echo "=================================================================="
echo "🎉 RELEASE PUBLISHED SUCCESSFULLY!"
echo "=================================================================="
echo "📦 Version      : v$VERSION_NAME ($VERSION_CODE)"
echo "🔒 SHA-256 Hash : $SHA256"
echo "📥 Download URL : $BASE_URL$DOWNLOAD_URL"
echo "✨ Doctors' apps will now automatically detect and offer this update!"
echo "=================================================================="
