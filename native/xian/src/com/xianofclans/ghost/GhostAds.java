package com.xianofclans.ghost;
import android.content.SharedPreferences;
import com.google.android.gms.ads.*;
import com.google.android.gms.ads.interstitial.*;
import com.google.android.ump.*;
import com.godot.game.R;

/** Interstitials only at level boundaries, once per two completed games. */
final class GhostAds {
 private final GhostMatchActivity host;
 private final SharedPreferences prefs;
 private final ConsentInformation consent;
 private InterstitialAd ad;
 private boolean initialized,loading,showing,closed;
 private long loadedAt;
 private boolean allowed(){return consent.canRequestAds()||host.getString(R.string.xian_interstitial_id).equals("ca-app-pub-3940256099942544/1033173712");}
 GhostAds(GhostMatchActivity host){
  this.host=host;prefs=host.getSharedPreferences("xian_ads_"+host.profileId,0);
  consent=UserMessagingPlatform.getConsentInformation(host);
  consent.requestConsentInfoUpdate(host,new ConsentRequestParameters.Builder().build(),()->{
   UserMessagingPlatform.loadAndShowConsentFormIfRequired(host,error->initialize());initialize();
  },error->initialize());initialize();
 }
 private void initialize(){if(closed||initialized||!allowed())return;initialized=true;
  MobileAds.initialize(host,status->host.runOnUiThread(this::load));}
 private void load(){if(closed||loading||ad!=null||!initialized||!allowed())return;loading=true;
  InterstitialAd.load(host,host.getString(R.string.xian_interstitial_id),new AdRequest.Builder().build(),new InterstitialAdLoadCallback(){
   @Override public void onAdLoaded(InterstitialAd value){loading=false;if(!closed){ad=value;loadedAt=System.currentTimeMillis();}}
   @Override public void onAdFailedToLoad(LoadAdError error){loading=false;ad=null;}
  });
 }
 void completed(){prefs.edit().putInt("wins",prefs.getInt("wins",0)+1).apply();load();}
 void betweenLevels(Runnable next){
  if(showing)return;
  if(ad!=null&&System.currentTimeMillis()-loadedAt>3500000)ad=null;
  if(prefs.getInt("wins",0)<2||ad==null||closed){load();next.run();return;}
  InterstitialAd ready=ad;ad=null;showing=true;
  ready.setFullScreenContentCallback(new FullScreenContentCallback(){
   private boolean continued;
   private void proceed(){if(continued)return;continued=true;showing=false;load();if(!closed)next.run();}
   @Override public void onAdShowedFullScreenContent(){prefs.edit().putInt("wins",0).apply();}
   @Override public void onAdDismissedFullScreenContent(){proceed();}
   @Override public void onAdFailedToShowFullScreenContent(AdError error){proceed();}
  });ready.show(host);
 }
 boolean needsPrivacy(){return consent.getPrivacyOptionsRequirementStatus()==ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED;}
 void privacy(){UserMessagingPlatform.showPrivacyOptionsForm(host,error->{ad=null;initialize();load();});}
 void close(){closed=true;ad=null;}
}
