#!/bin/bash
# Run this AFTER: flutter create . --platforms=android,web
# It fixes the app label from "freight_flow" to "FreightFlow"

MANIFEST="android/app/src/main/AndroidManifest.xml"
STRINGS="android/app/src/main/res/values/strings.xml"

if [ ! -f "$MANIFEST" ]; then
  echo "ERROR: Run 'flutter create . --platforms=android,web' first"
  exit 1
fi

# Fix 1: android:label in AndroidManifest.xml
sed -i 's/android:label="freight_flow"/android:label="FreightFlow"/g' "$MANIFEST"
echo "✓ Fixed AndroidManifest.xml label"

# Fix 2: Also update strings.xml if it exists
if [ -f "$STRINGS" ]; then
  sed -i 's/<string name="app_name">freight_flow<\/string>/<string name="app_name">FreightFlow<\/string>/g' "$STRINGS"
  echo "✓ Fixed strings.xml app_name"
fi

echo ""
echo "Done! App will now show as 'FreightFlow' on Android home screen."
echo "Run: flutter run"
