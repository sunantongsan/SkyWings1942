package com.xianofclans.auth;
import android.app.Activity;
import android.os.Bundle;
import android.content.Intent;
public class OAuthCallbackActivity extends Activity {
 @Override protected void onCreate(Bundle state){
  super.onCreate(state);
  XianAuth plugin=XianAuth.instance;
  if(plugin!=null)plugin.receive(getIntent());
  Intent launch=getPackageManager().getLaunchIntentForPackage(getPackageName());
  if(launch!=null){launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK|Intent.FLAG_ACTIVITY_CLEAR_TOP);startActivity(launch);}
  finish();
 }
}
