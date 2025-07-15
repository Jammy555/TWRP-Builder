#!/bin/bash

# TWRP Build Debug Script for Motorola Capri
# This script helps troubleshoot TWRP build issues

set -e

echo "=== TWRP Build Debug Script ==="
echo "Device: Motorola Capri"
echo "Date: $(date)"
echo ""

# Check if we're in the right directory
if [ ! -d "device/motorola/capri" ]; then
    echo "❌ Error: device/motorola/capri not found"
    echo "Please run this script from the TWRP source root"
    exit 1
fi

DEVICE_PATH="device/motorola/capri"
DEVICE_NAME="capri"

echo "✅ Device tree found at: $DEVICE_PATH"
echo ""

# Check essential files
echo "=== Essential Files Check ==="
essential_files=(
    "$DEVICE_PATH/BoardConfig.mk"
    "$DEVICE_PATH/device.mk"
    "$DEVICE_PATH/recovery.fstab"
    "$DEVICE_PATH/twrp_capri.mk"
    "$DEVICE_PATH/AndroidProducts.mk"
    "$DEVICE_PATH/vendorsetup.sh"
)

for file in "${essential_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
    fi
done
echo ""

# Check recovery structure
echo "=== Recovery Structure Check ==="
recovery_paths=(
    "$DEVICE_PATH/recovery/root"
    "$DEVICE_PATH/recovery/root/system"
    "$DEVICE_PATH/recovery/root/system/bin"
    "$DEVICE_PATH/recovery/root/system/etc"
    "$DEVICE_PATH/recovery/root/vendor"
    "$DEVICE_PATH/recovery/root/vendor/etc"
    "$DEVICE_PATH/recovery/root/vendor/lib64"
    "$DEVICE_PATH/recovery/root/vendor/firmware"
)

for path in "${recovery_paths[@]}"; do
    if [ -d "$path" ]; then
        file_count=$(find "$path" -type f 2>/dev/null | wc -l)
        echo "✅ $path exists ($file_count files)"
    else
        echo "❌ $path missing"
    fi
done
echo ""

# Check dependencies
echo "=== Dependencies Check ==="
if [ -f "$DEVICE_PATH/twrp.dependencies" ]; then
    echo "✅ twrp.dependencies found"
    echo "Content:"
    cat "$DEVICE_PATH/twrp.dependencies"
else
    echo "❌ twrp.dependencies missing"
fi
echo ""

# Check BoardConfig.mk configuration
echo "=== BoardConfig.mk Configuration Check ==="
if [ -f "$DEVICE_PATH/BoardConfig.mk" ]; then
    echo "Checking TWRP configuration..."
    
    # Check TWRP flags
    twrp_flags=(
        "TW_THEME"
        "TW_EXTRA_LANGUAGES"
        "TW_INCLUDE_CRYPTO"
        "TW_INCLUDE_RESETPROP"
        "TARGET_RECOVERY_PIXEL_FORMAT"
        "TARGET_RECOVERY_FSTAB"
    )
    
    for flag in "${twrp_flags[@]}"; do
        if grep -q "$flag" "$DEVICE_PATH/BoardConfig.mk"; then
            value=$(grep "$flag" "$DEVICE_PATH/BoardConfig.mk" | head -1)
            echo "✅ $value"
        else
            echo "❌ $flag not found"
        fi
    done
else
    echo "❌ BoardConfig.mk not found"
fi
echo ""

# Check device.mk configuration
echo "=== device.mk Configuration Check ==="
if [ -f "$DEVICE_PATH/device.mk" ]; then
    echo "Checking device configuration..."
    
    # Check essential variables
    device_vars=(
        "PRODUCT_COPY_FILES"
        "AB_OTA_UPDATER"
        "PRODUCT_PACKAGES"
    )
    
    for var in "${device_vars[@]}"; do
        if grep -q "$var" "$DEVICE_PATH/device.mk"; then
            count=$(grep -c "$var" "$DEVICE_PATH/device.mk")
            echo "✅ $var found ($count occurrences)"
        else
            echo "❌ $var not found"
        fi
    done
else
    echo "❌ device.mk not found"
fi
echo ""

# Check build environment
echo "=== Build Environment Check ==="
if [ -f "build/envsetup.sh" ]; then
    echo "✅ TWRP source environment found"
    
    # Check available products
    source build/envsetup.sh >/dev/null 2>&1 || true
    if command -v lunch >/dev/null 2>&1; then
        echo "✅ lunch command available"
    else
        echo "❌ lunch command not available"
    fi
else
    echo "❌ TWRP source environment not found"
fi
echo ""

# Check for common issues
echo "=== Common Issues Check ==="

# Check for hardcoded paths
if grep -q "TODO.*Fix hardcoded" "$DEVICE_PATH/BoardConfig.mk" 2>/dev/null; then
    echo "⚠️  Found TODO comments for hardcoded values"
else
    echo "✅ No hardcoded value TODOs found"
fi

# Check for missing dependencies
if [ ! -f "$DEVICE_PATH/twrp.dependencies" ]; then
    echo "⚠️  No dependencies file found - build may fail"
else
    echo "✅ Dependencies file found"
fi

# Check recovery size
if [ -d "$DEVICE_PATH/recovery/root" ]; then
    size=$(du -sh "$DEVICE_PATH/recovery/root" 2>/dev/null | cut -f1)
    echo "📦 Recovery dependencies size: $size"
else
    echo "❌ Recovery root directory not found"
fi
echo ""

# Check build readiness
echo "=== Build Readiness Check ==="
readiness_score=0
max_score=10

# Essential files (5 points)
if [ -f "$DEVICE_PATH/BoardConfig.mk" ] && [ -f "$DEVICE_PATH/device.mk" ]; then
    readiness_score=$((readiness_score + 2))
fi

# Recovery structure (3 points)
if [ -d "$DEVICE_PATH/recovery/root" ]; then
    readiness_score=$((readiness_score + 2))
fi

# Dependencies (2 points)
if [ -f "$DEVICE_PATH/twrp.dependencies" ]; then
    readiness_score=$((readiness_score + 1))
fi

# TWRP configuration (3 points)
if grep -q "TW_THEME" "$DEVICE_PATH/BoardConfig.mk" 2>/dev/null; then
    readiness_score=$((readiness_score + 2))
fi

echo "Build Readiness Score: $readiness_score/$max_score"

if [ $readiness_score -ge 8 ]; then
    echo "✅ Device tree is ready for TWRP compilation!"
elif [ $readiness_score -ge 6 ]; then
    echo "⚠️  Device tree needs minor fixes before compilation"
else
    echo "❌ Device tree needs significant fixes before compilation"
fi

echo ""
echo "=== Debug Script Complete ==="
echo "For more detailed debugging, check the build logs and error messages." 