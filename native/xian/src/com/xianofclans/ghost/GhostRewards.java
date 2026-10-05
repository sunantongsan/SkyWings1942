package com.xianofclans.ghost;

import android.content.SharedPreferences;
import org.json.*;
import java.net.*;
import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicBoolean;

/** Durable per-account FIFO. Tokens stay in memory; retries reuse the same request UUID. */
final class GhostRewards {
 private static final Object LOCK=new Object();
 private final GhostMatchActivity host;
 private final SharedPreferences prefs;
 private final String token;
 private final ExecutorService executor=Executors.newSingleThreadExecutor();
 private final AtomicBoolean running=new AtomicBoolean();
 private volatile boolean closed;
 private String ticket="";
 GhostRewards(GhostMatchActivity host,String token){
  this.host=host;this.token=token==null?"":token;
  prefs=host.getSharedPreferences("xian_rewards_"+host.profileId,0);drain();
 }
 private JSONArray read(){try{return new JSONArray(prefs.getString("queue","[]"));}catch(JSONException e){return new JSONArray();}}
 void begin(int level){ticket=UUID.randomUUID().toString();enqueue("ghost_begin",level,ticket,"");}
 void win(int level){if(!ticket.isEmpty())enqueue("ghost_win",level,UUID.randomUUID().toString(),ticket);}
 private void enqueue(String action,int level,String request,String round){
  synchronized(LOCK){try{
   JSONArray queue=read();JSONObject args=new JSONObject().put("level",level);
   if(!round.isEmpty())args.put("ticket",round);
   queue.put(new JSONObject().put("p_action",action).put("p_args",args).put("p_request",request));
   prefs.edit().putString("queue",queue.toString()).commit();
  }catch(JSONException e){host.rewardStatus("บันทึกรางวัลไม่สำเร็จ กรุณาเปิดเกมใหม่");return;}}
  drain();
 }
 void drain(){
  if(closed||token.isEmpty()||!running.compareAndSet(false,true))return;
  executor.execute(()->{
   boolean drained=false;
   try{while(!closed){
    JSONObject event;
    synchronized(LOCK){JSONArray queue=read();if(queue.length()==0){drained=true;break;}event=queue.getJSONObject(0);}
    JSONObject result=post(event);
    if(result.has("message")){
     if(result.optString("message").contains("รอบเกมสั้นเกินไป")){Thread.sleep(3200);continue;}
     host.rewardStatus("รางวัลรอส่ง • กลับสำนักแล้วเปิดเกมจับคู่อีกครั้ง");break;
    }
    if(!result.has("state")){host.rewardStatus("รางวัลรอเชื่อมต่อบัญชี");break;}
    synchronized(LOCK){
     JSONArray queue=read();
     if(queue.length()>0&&queue.getJSONObject(0).optString("p_request").equals(event.optString("p_request"))){queue.remove(0);prefs.edit().putString("queue",queue.toString()).commit();}
    }
    if("ghost_win".equals(event.optString("p_action"))){
     JSONObject state=result.getJSONObject("state");JSONObject round=state.optJSONObject("ghost_ticket");
     int amount=round==null?0:round.optInt("reward_jade",0);
     host.rewardStatus(amount>0?"รับแล้ว "+amount+" หยก • ส่งเข้าสำนักเรียบร้อย":"ส่งรางวัลเข้าสำนักเรียบร้อย");
    }else if("ghost_begin".equals(event.optString("p_action"))){
     int amount=result.getJSONObject("state").optInt("match_reward_jade",2);
     host.rewardStatus("ผ่านด่านรับ "+amount+" หยก"+(amount==50?" • ช่วงทดสอบก่อนครบ 100 สมาชิก":"")+" • โฆษณาทุก 2 ด่าน");
    }
   }}catch(Exception e){host.rewardStatus("รางวัลรอส่ง • เชื่อมต่อแล้วเปิดเกมจับคู่อีกครั้ง");}
   finally{synchronized(LOCK){running.set(false);if(drained&&!closed&&read().length()>0)drain();}}
  });
 }
 private JSONObject post(JSONObject event)throws Exception{
  HttpURLConnection c=(HttpURLConnection)new URL("https://uzinxxeadejmzxqmqqtx.supabase.co/rest/v1/rpc/xian_action").openConnection();
  try{
   c.setConnectTimeout(12000);c.setReadTimeout(12000);c.setRequestMethod("POST");c.setDoOutput(true);
   c.setRequestProperty("Content-Type","application/json");c.setRequestProperty("apikey","sb_publishable_4R8VSfnmuFq6hAgWRtDX6Q_IcSVh82m");c.setRequestProperty("Authorization","Bearer "+token);
   try(OutputStream out=c.getOutputStream()){out.write(event.toString().getBytes(StandardCharsets.UTF_8));}
   int status=c.getResponseCode();InputStream in=status<300?c.getInputStream():c.getErrorStream();
   if(in==null)throw new IOException("No response");ByteArrayOutputStream data=new ByteArrayOutputStream();
   try(InputStream stream=in){byte[] buffer=new byte[4096];int n;while((n=stream.read(buffer))!=-1){data.write(buffer,0,n);if(data.size()>1048576)throw new IOException("Response too large");}}
   return new JSONObject(data.toString("UTF-8"));
  }finally{c.disconnect();}
 }
 void close(){closed=true;executor.shutdown();}
}
