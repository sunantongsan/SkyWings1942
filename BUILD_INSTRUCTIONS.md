# SkyWings1942 - APK Debug Build Instructions

## 📱 สร้าง APK ทดสอบ (Debug APK)

### วิธีที่ 1: ใช้ Android Studio
1. เปิด Android Studio
2. ไปที่ **Build** → **Build Bundle(s) / APK(s)** → **Build APK(s)**
3. รอให้ build เสร็จ
4. APK จะอยู่ที่ `app/build/outputs/apk/debug/`

### วิธีที่ 2: ใช้ Command Line (Gradle)

#### บน Mac/Linux:
```bash
./gradlew assembleDebug
```

#### บน Windows:
```bash
gradlew.bat assembleDebug
```

APK จะสร้างที่: `app/build/outputs/apk/debug/app-debug.apk`

## 📦 ติดตั้ง APK บนอุปกรณ์

### วิธีที่ 1: ใช้ Android Studio
1. เชื่อมต่ออุปกรณ์ Android กับคอม
2. ไปที่ **Run** → **Run 'app'**

### วิธีที่ 2: ใช้ ADB (Android Debug Bridge)
```bash
adb install app/build/outputs/apk/debug/app-debug.apk
```

## 🔧 ไฟล์ที่เตรียมไว้

✅ `app/build.gradle` - Build configuration ที่สมบูรณ์  
✅ `gradle.properties` - Gradle settings  
✅ `app/proguard-rules.pro` - ProGuard rules สำหรับ release build  
✅ `.gitignore` - Git ignore rules  

## 📋 เวอร์ชั่นปัจจุบัน
- **Version Name:** 1.1
- **Version Code:** 2
- **Target SDK:** 36
- **Min SDK:** 23

## ⚠️ หมายเหตุสำคัญ
- Debug APK: `com.skywings.reborn.debug` (เพื่อติดตั้งเคียงข้าง release build)
- Release APK: `com.skywings.reborn` (สำหรับ PlayStore)

## 🚀 ขั้นตอนต่อไป (หลังจาก Debug APK ใช้ได้)
1. ปรับปรุง versionCode → 3, versionName → 1.2 (เมื่อพร้อม)
2. สร้าง Signing Key สำหรับ Release
3. Build Release APK
4. อัพไปร PlayStore Console
