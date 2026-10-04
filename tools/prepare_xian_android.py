"""Install native OAuth callback transport into a clean Godot 4.4.1 template."""
from pathlib import Path
import shutil
root = Path(__file__).resolve().parents[1]
build = root / 'xian/android/build'
shutil.copytree(root / 'native/xian/src', build / 'src', dirs_exist_ok=True)
p = build / 'AndroidManifest.xml'
s = p.read_text()
marker = 'org.godotengine.plugin.v2.XianAuth'
if marker not in s:
    s = s.replace('<profileable', '<meta-data android:name="'+marker+'" android:value="com.xianofclans.auth.XianAuth" />\n        <profileable')
    s = s.replace('</activity>', '''<intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="com.sunantongsan.thegang" android:host="auth-callback" />
            </intent-filter>
        </activity>''', 1)
    p.write_text(s)
p = build / 'config.gradle'
s = p.read_text().replace("compileSdk         : 34", "compileSdk         : 35").replace("buildTools         : '34.0.0'", "buildTools         : '35.0.1'")
p.write_text(s)
(root / 'xian/android/.gdignore').touch()
(root / 'xian/android/.build_version').write_text('4.4.1.stable')
