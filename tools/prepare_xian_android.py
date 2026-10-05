"""Install native OAuth callback transport into a clean Godot 4.4.1 template."""
from pathlib import Path
import shutil
from fetch_ghost_assets import fetch
fetch()
root = Path(__file__).resolve().parents[1]
build = root / 'xian/android/build'
shutil.copytree(root / 'native/xian/src', build / 'src', dirs_exist_ok=True)
shutil.copytree(root / 'native/xian/res', build / 'res', dirs_exist_ok=True)
p = build / 'AndroidManifest.xml'
s = p.read_text()
marker = 'org.godotengine.plugin.v2.XianAuth'
if marker not in s:
    s = s.replace('<profileable', '<meta-data android:name="'+marker+'" android:value="com.xianofclans.auth.XianAuth" />\n        <profileable')
    s = s.replace('</application>', '''<activity android:name="com.xianofclans.auth.OAuthCallbackActivity" android:exported="true" android:theme="@android:style/Theme.NoDisplay">
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="com.sunantongsan.thegang" android:host="auth-callback" />
            </intent-filter>
        </activity>
    </application>''', 1)
    p.write_text(s)
if 'com.xianofclans.ghost.GhostMatchActivity' not in s:
    s=s.replace('</application>', '<activity android:name="com.xianofclans.ghost.GhostMatchActivity" android:exported="false" android:screenOrientation="portrait" android:theme="@android:style/Theme.Material.Light.NoActionBar" />\n    </application>')
    p.write_text(s)
p = build / 'config.gradle' 
s = p.read_text().replace("compileSdk         : 34", "compileSdk         : 35").replace("buildTools         : '34.0.0'", "buildTools         : '35.0.1'")
p.write_text(s)
(root / 'xian/android/.gdignore').touch()
(root / 'xian/android/.build_version').write_text('4.4.1.stable')

# AdMob test placement by default; production IDs belong to this game's app.
import os,re
app_id=os.environ.get('XIAN_ADMOB_APP_ID','ca-app-pub-3940256099942544~3347511713')
unit_id=os.environ.get('XIAN_ADMOB_INTERSTITIAL_ID','ca-app-pub-3940256099942544/1033173712')
if not re.fullmatch(r'ca-app-pub-\d{16}~\d{10}',app_id) or not re.fullmatch(r'ca-app-pub-\d{16}/\d{10}',unit_id):
    raise ValueError('Invalid Xian AdMob IDs')
p=build/'AndroidManifest.xml';s=p.read_text()
if 'com.google.android.gms.ads.APPLICATION_ID' not in s:
    s=s.replace('</application>',f'<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="{app_id}" />\n</application>')
p.write_text(s)
p=build/'res/values/xian_ads.xml';p.parent.mkdir(parents=True,exist_ok=True)
p.write_text(f'<resources><string name="xian_interstitial_id">{unit_id}</string></resources>')
p=build/'build.gradle';s=p.read_text()
if 'play-services-ads' not in s:
    s += "\ndependencies {\n implementation 'com.google.android.gms:play-services-ads:25.4.0'\n implementation 'com.google.android.ump:user-messaging-platform:4.0.0'\n}\n"
p.write_text(s)
