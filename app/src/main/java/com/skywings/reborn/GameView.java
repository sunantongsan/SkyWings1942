package com.skywings.reborn;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.*;
import android.view.MotionEvent;
import android.view.View;
import java.util.ArrayList;
import java.util.Random;

public class GameView extends View {
    private static final int SPLASH=0, BASE=1, BUILD=2, TRAIN=3, GALAXY=4, PREP=5, BATTLE=6, VICTORY=7;
    private final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Random rnd=new Random(1942);
    private final SharedPreferences prefs;

    private Bitmap uiAtlas, buildingAtlas;
    private int screen=SPLASH, selectedBuilding=0, selectedUnit=0, selectedPlanet=0;
    private long credits=125600, metal=230400, oil=98200, crystal=56100;
    private final int[] buildingLevel={5,4,4,4,4,3,4,3,3,2};
    private final int[] unitStock={20,10,5,10};
    private long lastTick;

    private static class Enemy {
        float x,y; int type,hp,maxHp; boolean dead;
        Enemy(float x,float y,int type,int hp){this.x=x;this.y=y;this.type=type;this.hp=this.maxHp=hp;}
    }
    private static class Troop {
        float x,y; int type; float speed,damage;
        Troop(float x,float y,int type){this.x=x;this.y=y;this.type=type;speed=type==2?.0012f:.0019f;damage=type==1?8:(type==2?6:4);}
    }

    private final ArrayList<Enemy> enemies=new ArrayList<>();
    private final ArrayList<Troop> troops=new ArrayList<>();
    private int damage=0;
    private long battleStart=0;
    private boolean lootGranted=false;

    public GameView(Context c){
        super(c);
        setFocusable(true); setClickable(true);
        prefs=c.getSharedPreferences("galaxy1942_rts31",Context.MODE_PRIVATE);
        uiAtlas=BitmapFactory.decodeResource(getResources(),R.drawable.galaxy1942_ui_atlas_hd);
        buildingAtlas=BitmapFactory.decodeResource(getResources(),R.drawable.galaxy1942_buildings_hd);
        credits=prefs.getLong("credits",credits); metal=prefs.getLong("metal",metal);
        oil=prefs.getLong("oil",oil); crystal=prefs.getLong("crystal",crystal);
        lastTick=System.currentTimeMillis();
    }

    private void save(){
        prefs.edit().putLong("credits",credits).putLong("metal",metal).putLong("oil",oil).putLong("crystal",crystal).apply();
    }
    private void txt(Canvas c,String s,float x,float y,float size,int color,Paint.Align a){
        p.setShader(null);p.setStyle(Paint.Style.FILL);p.setColor(color);p.setTextAlign(a);
        p.setTypeface(Typeface.create("sans",Typeface.BOLD));p.setTextSize(size);c.drawText(s,x,y,p);
    }
    private void box(Canvas c,float l,float t,float r,float b,float rad,int color){
        p.setShader(null);p.setStyle(Paint.Style.FILL);p.setColor(color);c.drawRoundRect(l,t,r,b,rad,rad,p);
    }
    private void stroke(Canvas c,float l,float t,float r,float b,float rad,float sw,int color){
        p.setShader(null);p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(sw);p.setColor(color);c.drawRoundRect(l,t,r,b,rad,rad,p);
    }

    @Override protected void onDraw(Canvas c){
        tickEconomy();
        switch(screen){
            case SPLASH: drawPanel(c,0); drawSplashOverlay(c); break;
            case BASE: drawPanel(c,2); drawBaseOverlay(c); break;
            case BUILD: drawPanel(c,3); drawBuildOverlay(c); break;
            case TRAIN: drawPanel(c,4); drawTrainOverlay(c); break;
            case GALAXY: drawPanel(c,1); drawGalaxyOverlay(c); break;
            case PREP: drawPanel(c,5); drawPrepOverlay(c); break;
            case BATTLE: drawPanel(c,6); updateBattle(); drawBattleOverlay(c); break;
            case VICTORY: drawPanel(c,7); drawVictoryOverlay(c); break;
        }
        postInvalidateDelayed(33);
    }

    private void tickEconomy(){
        long now=System.currentTimeMillis();
        long s=(now-lastTick)/1000;
        if(s<=0)return;
        lastTick+=s*1000;
        credits=Math.min(9999999,credits+s*8);
        metal=Math.min(9999999,metal+s*4);
        oil=Math.min(9999999,oil+s*3);
        crystal=Math.min(9999999,crystal+s*2);
    }

    // atlas layout from generated 1536x1024 concept
    private void drawPanel(Canvas c,int id){
        if(uiAtlas==null){c.drawColor(0xff020712);return;}
        Rect src;
        switch(id){
            case 0: src=new Rect(0,0,510,438); break;            // splash
            case 1: src=new Rect(510,0,1002,438); break;          // galaxy
            case 2: src=new Rect(1002,0,1536,438); break;         // home
            case 3: src=new Rect(0,438,510,738); break;           // buildings
            case 4: src=new Rect(510,438,944,738); break;         // train
            case 5: src=new Rect(944,438,1536,738); break;        // prep
            case 6: src=new Rect(0,738,585,1024); break;          // battle
            default: src=new Rect(585,738,1002,1024); break;      // victory
        }
        p.setAlpha(255);p.setFilterBitmap(true);
        c.drawBitmap(uiAtlas,src,new RectF(0,0,getWidth(),getHeight()),p);
    }

    private void drawTopResources(Canvas c){
        int W=getWidth();
        box(c,W*.42f,8,W-16,58,12,0xbb04101c);
        txt(c,"C "+credits+"   M "+metal+"   O "+oil+"   Crys "+crystal,W-28,40,15,0xffffdf72,Paint.Align.RIGHT);
    }

    private void drawSplashOverlay(Canvas c){
        int W=getWidth(),H=getHeight();
        box(c,W*.61f,H*.18f,W*.94f,H*.31f,20,0xddee8a00);
        stroke(c,W*.61f,H*.18f,W*.94f,H*.31f,20,3,0xffffd876);
        txt(c,"PLAY",W*.775f,H*.265f,28,Color.WHITE,Paint.Align.CENTER);
        box(c,W*.61f,H*.35f,W*.94f,H*.46f,16,0xcc0a2847);
        txt(c,"GALAXY",W*.775f,H*.42f,18,Color.WHITE,Paint.Align.CENTER);
    }

    private void drawBaseOverlay(Canvas c){
        int W=getWidth(),H=getHeight();
        drawTopResources(c);
        box(c,12,72,145,122,14,0xcc092c4b);txt(c,"BUILD",78,105,16,Color.WHITE,Paint.Align.CENTER);
        box(c,12,132,145,182,14,0xcc092c4b);txt(c,"TRAIN",78,165,16,Color.WHITE,Paint.Align.CENTER);
        box(c,12,192,145,242,14,0xcc092c4b);txt(c,"GALAXY",78,225,16,Color.WHITE,Paint.Align.CENTER);
        box(c,W-160,H-78,W-18,H-18,16,0xddff7800);txt(c,"ATTACK",W-89,H-40,18,Color.WHITE,Paint.Align.CENTER);
    }

    private void drawBuildOverlay(Canvas c){
        int W=getWidth(),H=getHeight();
        drawTopResources(c);
        box(c,12,H-64,130,H-14,14,0xcc334c61);txt(c,"BACK",71,H-31,15,Color.WHITE,Paint.Align.CENTER);
        float cardW=W*.17f, start=W*.04f, gap=W*.018f;
        for(int i=0;i<5;i++){
            float l=start+i*(cardW+gap),r=l+cardW;
            if(i==selectedBuilding)stroke(c,l,H*.11f,r,H*.43f,14,4,0xffffc44c);
        }
        for(int i=5;i<10;i++){
            int j=i-5;float l=start+j*(cardW+gap),r=l+cardW;
            if(i==selectedBuilding)stroke(c,l,H*.47f,r,H*.79f,14,4,0xffffc44c);
        }
        int cost=1200+selectedBuilding*200;
        box(c,W*.73f,H*.84f,W*.96f,H*.96f,16,0xdd168447);
        txt(c,"BUILD / UPGRADE",W*.845f,H*.90f,16,Color.WHITE,Paint.Align.CENTER);
        txt(c,"Cost "+cost+" Metal",W*.845f,H*.945f,12,0xffffdf72,Paint.Align.CENTER);
    }

    private void drawTrainOverlay(Canvas c){
        int W=getWidth(),H=getHeight();
        drawTopResources(c);
        box(c,12,H-64,130,H-14,14,0xcc334c61);txt(c,"BACK",71,H-31,15,Color.WHITE,Paint.Align.CENTER);
        String[] n={"FIGHTER","BOMBER","HEAVY","DRONE"};
        for(int i=0;i<4;i++){
            float l=W*(.08f+i*.22f),r=l+W*.18f;
            if(i==selectedUnit)stroke(c,l,H*.18f,r,H*.70f,16,4,0xffffc44c);
            txt(c,n[i]+" x"+unitStock[i],(l+r)/2,H*.74f,14,Color.WHITE,Paint.Align.CENTER);
        }
        box(c,W*.73f,H*.83f,W*.96f,H*.95f,16,0xdd1e70a3);
        txt(c,"TRAIN +1",W*.845f,H*.90f,17,Color.WHITE,Paint.Align.CENTER);
    }

    private void drawGalaxyOverlay(Canvas c){
        int W=getWidth(),H=getHeight();
        drawTopResources(c);
        box(c,12,H-64,130,H-14,14,0xcc334c61);txt(c,"HOME",71,H-31,15,Color.WHITE,Paint.Align.CENTER);
        float[][] pts={{.36f,.23f},{.52f,.19f},{.67f,.26f},{.43f,.39f},{.58f,.42f},{.75f,.36f},{.39f,.59f},{.55f,.61f},{.71f,.58f},{.61f,.76f}};
        for(int i=0;i<10;i++){
            float x=W*pts[i][0],y=H*pts[i][1];
            if(i==selectedPlanet){p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(4);p.setColor(0xff68ff8b);c.drawCircle(x,y,32,p);}
        }
        box(c,W*.78f,H*.72f,W*.96f,H*.84f,14,0xdddf3f32);txt(c,"ATTACK",W*.87f,H*.795f,17,Color.WHITE,Paint.Align.CENTER);
    }

    private void drawPrepOverlay(Canvas c){
        int W=getWidth(),H=getHeight();
        drawTopResources(c);
        box(c,14,H-64,135,H-14,14,0xcc334c61);txt(c,"BACK",74,H-31,15,Color.WHITE,Paint.Align.CENTER);
        txt(c,"Fighter x"+unitStock[0]+"   Bomber x"+unitStock[1]+"   Heavy x"+unitStock[2]+"   Drone x"+unitStock[3],W*.58f,H*.72f,16,Color.WHITE,Paint.Align.CENTER);
        box(c,W*.70f,H*.80f,W*.96f,H*.94f,18,0xdd4cae2a);txt(c,"START ATTACK",W*.83f,H*.885f,20,Color.WHITE,Paint.Align.CENTER);
    }

    private void setupBattle(){
        enemies.clear();troops.clear();damage=0;lootGranted=false;battleStart=System.currentTimeMillis();
        enemies.add(new Enemy(.50f,.28f,0,500));
        enemies.add(new Enemy(.30f,.35f,8,220)); enemies.add(new Enemy(.70f,.36f,8,220));
        enemies.add(new Enemy(.42f,.46f,9,260)); enemies.add(new Enemy(.61f,.45f,6,200));
        enemies.add(new Enemy(.24f,.48f,2,180)); enemies.add(new Enemy(.77f,.50f,3,180));
        for(int i=0;i<Math.min(8,unitStock[0]);i++)troops.add(new Troop(.38f+i*.025f,.83f,0));
        for(int i=0;i<Math.min(4,unitStock[1]);i++)troops.add(new Troop(.48f+i*.03f,.88f,1));
        for(int i=0;i<Math.min(3,unitStock[2]);i++)troops.add(new Troop(.58f+i*.035f,.86f,2));
    }

    private void updateBattle(){
        if(screen!=BATTLE)return;
        int aliveHp=0,totalHp=0;
        for(Enemy e:enemies){totalHp+=e.maxHp;if(!e.dead)aliveHp+=Math.max(0,e.hp);}
        damage=totalHp==0?0:(int)(100f*(totalHp-aliveHp)/totalHp);
        if(damage>=100 || System.currentTimeMillis()-battleStart>120000){
            screen=VICTORY;
            if(!lootGranted){credits+=3200;metal+=2100;oil+=1200;crystal+=600;lootGranted=true;save();}
            return;
        }
        for(Troop t:troops){
            Enemy target=null;float best=99;
            for(Enemy e:enemies){
                if(e.dead)continue;
                float d=(float)Math.hypot(e.x-t.x,e.y-t.y);
                if(d<best){best=d;target=e;}
            }
            if(target==null)continue;
            if(best>.035f){
                float dx=target.x-t.x,dy=target.y-t.y,d=Math.max(.001f,(float)Math.hypot(dx,dy));
                t.x+=dx/d*t.speed;t.y+=dy/d*t.speed;
            }else{
                target.hp-=Math.max(1,(int)t.damage);
                if(target.hp<=0)target.dead=true;
            }
        }
    }

    private void drawBattleOverlay(Canvas c){
        int W=getWidth(),H=getHeight();
        txt(c,"DAMAGE "+damage+"%",W-28,44,18,0xffffd75c,Paint.Align.RIGHT);
        for(Enemy e:enemies){
            if(e.dead)continue;
            float x=W*e.x,y=H*e.y;
            p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(3);p.setColor(0xffff5c4c);c.drawCircle(x,y,24,p);
        }
        for(Troop t:troops){
            float x=W*t.x,y=H*t.y;
            p.setStyle(Paint.Style.FILL);p.setColor(t.type==1?0xffff7a4f:(t.type==2?0xffffc84f:0xff66e8ff));
            Path q=new Path();q.moveTo(x,y-10);q.lineTo(x-8,y+8);q.lineTo(x+8,y+8);q.close();c.drawPath(q,p);
        }
        box(c,16,H-64,140,H-14,14,0xcc9f2e2e);txt(c,"RETREAT",78,H-31,14,Color.WHITE,Paint.Align.CENTER);
    }

    private void drawVictoryOverlay(Canvas c){
        int W=getWidth(),H=getHeight();
        box(c,W*.30f,H*.72f,W*.70f,H*.94f,18,0xdd07131e);
        txt(c,"VICTORY • "+damage+"% DESTROYED",W/2,H*.78f,24,0xffffd55a,Paint.Align.CENTER);
        txt(c,"Loot: +3200 Credits  +2100 Metal  +1200 Oil  +600 Crystal",W/2,H*.84f,14,Color.WHITE,Paint.Align.CENTER);
        box(c,W*.41f,H*.87f,W*.59f,H*.93f,12,0xdd2ba64a);txt(c,"RETURN HOME",W/2,H*.91f,14,Color.WHITE,Paint.Align.CENTER);
    }

    private int buildingAt(float nx,float ny){
        int col=Math.min(4,Math.max(0,(int)((nx-.04f)/.188f)));
        if(ny>.10f&&ny<.43f)return col;
        if(ny>.47f&&ny<.79f)return 5+col;
        return -1;
    }

    @Override public boolean onTouchEvent(MotionEvent e){
        if(e.getActionMasked()!=MotionEvent.ACTION_DOWN)return true;
        float x=e.getX(),y=e.getY();float nx=x/getWidth(),ny=y/getHeight();

        if(screen==SPLASH){
            if(nx>.58f&&nx<.98f&&ny>.14f&&ny<.34f)screen=BASE;
        }else if(screen==BASE){
            if(nx<.12f&&ny>.08f&&ny<.20f)screen=BUILD;
            else if(nx<.12f&&ny>.20f&&ny<.32f)screen=TRAIN;
            else if(nx<.12f&&ny>.32f&&ny<.45f)screen=GALAXY;
            else if(nx>.78f&&ny>.82f)screen=GALAXY;
        }else if(screen==BUILD){
            if(nx<.12f&&ny>.88f)screen=BASE;
            else{
                int b=buildingAt(nx,ny);
                if(b>=0)selectedBuilding=b;
                if(nx>.70f&&ny>.80f){
                    int cost=1200+selectedBuilding*200;
                    if(metal>=cost){metal-=cost;buildingLevel[selectedBuilding]++;save();}
                }
            }
        }else if(screen==TRAIN){
            if(nx<.12f&&ny>.88f)screen=BASE;
            else{
                for(int i=0;i<4;i++){
                    float l=.08f+i*.22f,r=l+.18f;
                    if(nx>l&&nx<r&&ny>.14f&&ny<.78f)selectedUnit=i;
                }
                if(nx>.70f&&ny>.80f){
                    int cost=200+selectedUnit*100;
                    if(credits>=cost&&oil>=cost/2){credits-=cost;oil-=cost/2;unitStock[selectedUnit]++;save();}
                }
            }
        }else if(screen==GALAXY){
            if(nx<.12f&&ny>.88f)screen=BASE;
            else{
                float[][] pts={{.36f,.23f},{.52f,.19f},{.67f,.26f},{.43f,.39f},{.58f,.42f},{.75f,.36f},{.39f,.59f},{.55f,.61f},{.71f,.58f},{.61f,.76f}};
                for(int i=0;i<10;i++)if(Math.hypot(nx-pts[i][0],ny-pts[i][1])<.06)selectedPlanet=i;
                if(nx>.76f&&ny>.68f)screen=PREP;
            }
        }else if(screen==PREP){
            if(nx<.12f&&ny>.88f)screen=GALAXY;
            else if(nx>.68f&&ny>.78f){setupBattle();screen=BATTLE;}
        }else if(screen==BATTLE){
            if(nx<.13f&&ny>.88f)screen=BASE;
        }else if(screen==VICTORY){
            if(nx>.38f&&nx<.62f&&ny>.84f)screen=BASE;
        }
        invalidate();return true;
    }

    @Override public boolean performClick(){super.performClick();return true;}
}