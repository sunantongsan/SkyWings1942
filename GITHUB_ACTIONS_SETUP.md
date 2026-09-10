# GitHub Actions Setup Complete ✅

## 📱 ว่าที่มี Workflows

### 1. **Build Debug APK** (`build-debug-apk.yml`)
- ทำงานทั้งเมื่อ push ไป main/develop และ pull request
- สร้าง Debug APK โดยอัตโนมัติ
- เก็บไฟล์ 30 วัน

**ทำงาน:**
- Push โค้ด → APK ถูกสร้างอัตโนมัติ
- เข้า GitHub Actions ดู Artifacts

### 2. **Build Release APK** (`build-release-apk.yml`)
- สร้างได้ด้วย Manual (workflow_dispatch)
- ใช้เมื่อต้องการสร้าง Release version

**วิธีใช้:**
1. ไปที่ GitHub → Actions
2. เลือก "Build Release APK"
3. คลิก "Run workflow"
4. ใส่ Version Name และ Version Code
5. รอให้สร้างเสร็จ → ดาวน์โหลด APK

---

## 🚀 **วิธีใช้ (ตรวจสอบ)**

### **ขั้นตอนที่ 1: Merge Branch**
```bash
# เมื่อพร้อม merge ci/github-actions-setup เข้า main
```

### **ขั้นตอนที่ 2: ทำการ Push**
```bash
git push origin ci/github-actions-setup
```
จากนั้นสร้าง Pull Request และ Merge

### **ขั้นตอนที่ 3: ตรวจสอบ Actions**
1. ไปที่ GitHub Repository
2. คลิก **Actions** tab
3. ดู workflows ทำงาน
4. เมื่อเสร็จ → ดาวน์โหลด APK จาก Artifacts

---

## 📥 **ดาวน์โหลด APK**

1. ไปที่ GitHub Actions
2. เลือก workflow run ล่าสุด
3. ไปที่ "Artifacts" section
4. ดาวน์โหลด `app-debug` หรือ `app-release`
5. ติดตั้งบนโทรศัพท์

---

## ⚙️ **ไฟล์ที่สร้าง**

✅ `.github/workflows/build-debug-apk.yml` - Debug build workflow  
✅ `.github/workflows/build-release-apk.yml` - Release build workflow  
✅ `BUILD_INSTRUCTIONS.md` - Guide สำหรับ build  

---

## 🎯 **ขั้นตอนถัดไป**

1. ✅ Review workflows (ทำให้เรียบร้อย)
2. ✅ Merge branch เข้า main
3. ✅ Push code → Actions ทำงานอัตโนมัติ
4. ✅ ดาวน์โหลด APK ทดสอบ
5. ✅ เมื่อพร้อม → สร้าง Release build
6. ✅ อัพไปร PlayStore (ต้องมี signing key)

---

## ⚠️ **สำคัญ!**

- Debug APK: `com.skywings.reborn.debug`
- Release APK: `com.skywings.reborn` (สำหรับ PlayStore)
- Release ต้องมี signing key (ทำครั้งเดียว)
