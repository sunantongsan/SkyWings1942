package com.xianofclans.auth;
import android.content.Intent;
import android.net.Uri;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.*;
import java.util.*;
/** Browser OAuth transport; PKCE and session exchange stay in the game API. */
public class XianAuth extends GodotPlugin {
 static volatile XianAuth instance;
 public XianAuth(Godot godot){super(godot);instance=this;}
 @Override public String getPluginName(){return "XianAuth";}
 @Override public Set<SignalInfo> getPluginSignals(){return new HashSet<>(Arrays.asList(new SignalInfo("oauth_callback",String.class)));}
 public void receive(Intent intent){
  Uri uri=intent.getData();
  if(uri!=null && "com.sunantongsan.thegang".equals(uri.getScheme()) && "auth-callback".equals(uri.getHost()))
   runOnRenderThread(() -> emitSignal("oauth_callback",uri.toString()));
 }
}
