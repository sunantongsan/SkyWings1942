package com.galaxy1942.ads;

import android.app.Activity;
import android.content.SharedPreferences;
import org.json.JSONArray;
import androidx.annotation.NonNull;
import com.google.android.gms.ads.*;
import com.google.android.gms.ads.rewarded.*;
import com.google.android.ump.*;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.*;
import java.util.HashSet;
import java.util.Arrays;
import java.util.Set;

/** Small Godot v2 bridge: Google demo rewarded inventory only; no interstitials. */
public final class GalaxyAds extends GodotPlugin {
    private static final String UNIT = "ca-app-pub-3940256099942544/5224354917";
    private RewardedAd ad;
    private volatile boolean ready = false;
    private boolean preparing = false, initialized = false, consentChecked = false;
    private volatile boolean showing = false;
    private long loadedAt = 0;
    private ConsentInformation consent;
    public GalaxyAds(Godot godot) { super(godot); }
    @NonNull @Override public String getPluginName() { return "GalaxyAds"; }
    @NonNull @Override public Set<SignalInfo> getPluginSignals() {
        return new HashSet<>(Arrays.asList(new SignalInfo("reward_earned", String.class),
            new SignalInfo("ad_closed", String.class), new SignalInfo("ad_status", String.class)));
    }
    private void status(String s) { emitSignal("ad_status", s); }
    @UsedByGodot public boolean is_ready() {
        return ready && android.os.SystemClock.elapsedRealtime() - loadedAt < 3500000;
    }
    @UsedByGodot public void prepare() {
        Activity activity = getActivity(); if (activity == null) return;
        activity.runOnUiThread(() -> {
            if (preparing || showing || is_ready()) return;
            preparing = true; ready = false; ad = null;
            if (consent == null) consent = UserMessagingPlatform.getConsentInformation(activity);
            if (consentChecked) { initializeAndLoad(activity); return; }
            consent.requestConsentInfoUpdate(activity, new ConsentRequestParameters.Builder().build(), () -> {
                UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity, error -> {
                    consentChecked = true;
                    if (consent.canRequestAds()) initializeAndLoad(activity);
                    else { preparing = false; status("Ad unavailable: check your connection or privacy choices."); }
                });
            }, error -> {
                if (consent.canRequestAds()) initializeAndLoad(activity);
                else { preparing = false; status("Ad unavailable. Try again when online."); }
            });
        });
    }
    private void initializeAndLoad(Activity activity) {
        if (!consent.canRequestAds()) { preparing = false; return; }
        if (!initialized) {
            MobileAds.setRequestConfiguration(new RequestConfiguration.Builder()
                .setMaxAdContentRating(RequestConfiguration.MAX_AD_CONTENT_RATING_PG).build());
            MobileAds.initialize(activity, ignored -> activity.runOnUiThread(() -> {
                initialized = true; load(activity);
            }));
        } else load(activity);
    }
    private void load(Activity activity) {
        RewardedAd.load(activity, UNIT, new AdRequest.Builder().build(), new RewardedAdLoadCallback() {
            @Override public void onAdLoaded(@NonNull RewardedAd value) {
                ad = value; loadedAt = android.os.SystemClock.elapsedRealtime(); ready = true; preparing = false;
                status("Test ad ready. Choose your reward and tap WATCH AD.");
            }
            @Override public void onAdFailedToLoad(@NonNull LoadAdError error) {
                ad = null; ready = false; preparing = false;
                status("No ad available right now. Your construction continues.");
            }
        });
    }
    @UsedByGodot public void show_rewarded(String token) {
        Activity activity = getActivity(); if (activity == null) { emitSignal("ad_closed", token); return; }
        activity.runOnUiThread(() -> {
            if (!is_ready() || ad == null || showing) { emitSignal("ad_closed", token); return; }
            RewardedAd current = ad; ad = null; ready = false; showing = true;
            final boolean[] rewarded = {false};
            current.setFullScreenContentCallback(new FullScreenContentCallback() {
                @Override public void onAdDismissedFullScreenContent() {
                    showing = false; emitSignal("ad_closed", token);
                }
                @Override public void onAdFailedToShowFullScreenContent(@NonNull AdError error) {
                    showing = false; emitSignal("ad_closed", token); status("Ad could not open. Try again later.");
                }
            });
            current.show(activity, reward -> {
                if (!rewarded[0]) {
                    rewarded[0] = true;
                    activity.getSharedPreferences("galaxy_google_earned_receipts", 0).edit().putBoolean(token, true).commit();
                    emitSignal("reward_earned", token);
                }
            });
        });
    }
    private SharedPreferences receipts() {
        return getActivity().getSharedPreferences("galaxy_google_earned_receipts", 0);
    }
    @UsedByGodot public boolean is_showing() { return showing; }
    @UsedByGodot public String get_reward_receipts() {
        if (getActivity() == null) return "[]";
        return new JSONArray(receipts().getAll().keySet()).toString();
    }
    @UsedByGodot public void ack_reward(String token) {
        if (getActivity() != null) receipts().edit().remove(token).commit();
    }
    @UsedByGodot public void privacy_options() {
        Activity activity = getActivity(); if (activity == null) return;
        activity.runOnUiThread(() -> {
            if (showing || preparing) { status("Please finish the current ad first."); return; }
            if (consent == null || consent.getPrivacyOptionsRequirementStatus() != ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED) {
                status("No additional ad privacy form is required right now."); return;
            }
            ready = false; ad = null;
            UserMessagingPlatform.showPrivacyOptionsForm(activity, error -> {
                if (error != null) status("Privacy form unavailable. Please try again.");
                else status("Ad privacy choices updated.");
            });
        });
    }
}
