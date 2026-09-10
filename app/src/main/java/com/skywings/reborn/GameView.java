package com.skywings.reborn;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.graphics.*;
import android.net.Uri;
import android.view.*;
import java.util.*;

/**
 * SKY WINGS 1942 REBORN
 * Original arcade shooter. No real-world aircraft branding or copyrighted sprites.
 * Boss defeat is the only condition that clears a stage.
 */
public class GameView extends View {
    static final String MONETAG_URL = "https://omg10.com/4/10852115";
    static final int MENU=0, PLAY=1, DEAD=2, CLEAR=3;
    static class Obj {
        float x,y,vx,vy,r; int type,hp; boolean alive=true;
        Obj(float x,float y,float r,int type){this.x=x;this.y=y;this.r=r;this.type=type;}
    }

    final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);
    final Random rng=new Random();
    final ArrayList<Obj> enemies=new ArrayList<>(), bullets=new ArrayList<>(), drops=new ArrayList<>(), stars=new ArrayList<>();
    final String[] ships={"FALCON","VIPER","PHANTOM","TYPHOON","AEGIS"};
    final int[] shipColor={Color.rgb(60,205,255),Color.rgb(255,82,92),Color.rgb(255,190,55),Color.rgb(188,92,255),Color.rgb(220,245,255)};
    final int[] enemyColor={Color.rgb(255,80,90),Color.rgb(255,155,45),Color.rgb(185,80,255),Color.rgb(65,230,190),Color.rgb(70,155,255),Color.rgb(255,80,190)};

    int screen=MENU, stage=1, wave=0, score=0, coins=0, gems=0, hp=100, power=1, shield=0, bomb=3;
    int enemiesKilled=0, enemiesTarget=8, bossMaxHp=50;
    boolean bossSpawned=false, bossDefeated=false, adPending=false, touchMove=false;
    long last, spawnTimer=0, shotTimer=0, adLaunchedAt=0, clearTimer=0;
    float px=0,py=0; int W,H; int ship=0;

    public GameView(Context c){
        super(c); setFocusable(true); last=System.currentTimeMillis();
        for(int i=0;i<120;i++){
            Obj s=new Obj(rng.nextInt(1000),rng.nextInt(1800),rng.nextFloat()*2.2f+.5f,0);
            s.vy=.35f+rng.nextFloat()*1.5f; stars.add(s);
        }
    }

    void text(Canvas c,String s,float x,float y,float size,int color,Paint.Align align){
        p.setStyle(Paint.Style.FILL); p.setColor(color); p.setTextSize(size); p.setTextAlign(align);
        p.setTypeface(Typeface.create("sans",Typeface.BOLD)); c.drawText(s,x,y,p);
    }
    void panel(Canvas c,float l,float t,float r,float b){
        p.setStyle(Paint.Style.FILL); p.setColor(Color.argb(225,5,14,31)); c.drawRoundRect(l,t,r,b,18,18,p);
        p.setStyle(Paint.Style.STROKE); p.setStrokeWidth(1.5f); p.setColor(Color.rgb(35,150,220)); c.drawRoundRect(l,t,r,b,18,18,p);
    }
    void bg(Canvas c){
        c.drawColor(Color.rgb(2,6,18));
        for(Obj s:stars){
            float sx=s.x/1000f*W, sy=s.y/1800f*H;
            p.setStyle(Paint.Style.FILL); p.setColor(Color.argb(80+(int)(s.vy*45),120,210,255)); c.drawCircle(sx,sy,s.r,p);
        }
        p.setStyle(Paint.Style.STROKE); p.setStrokeWidth(1); p.setColor(Color.argb(20,80,170,255));
        for(int y=100;y<H;y+=140)c.drawLine(0,y,W,y,p);
    }

    @Override protected void onDraw(Canvas c){
        W=getWidth(); H=getHeight();
        if(screen==PLAY) drawGame(c); else if(screen==CLEAR) drawClear(c); else if(screen==DEAD) drawDead(c); else drawMenu(c);
    }

    void drawMenu(Canvas c){
        bg(c);
        text(c,"SKY WINGS",W/2,105,48,Color.WHITE,Paint.Align.CENTER);
        text(c,"1942  REBORN",W/2,140,20,Color.rgb(255,190,50),Paint.Align.CENTER);
        text(c,"NEON SKY ARCADE",W/2,165,11,Color.rgb(90,190,225),Paint.Align.CENTER);
        panel(c,12,190,W-12,420);
        text(c,"CHOOSE YOUR FIGHTER",W/2,220,16,Color.WHITE,Paint.Align.CENTER);
        float gap=7,left=18,cardW=(W-36-gap*4)/5f;
        for(int i=0;i<5;i++){
            float l=left+i*(cardW+gap),r=l+cardW;
            p.setStyle(Paint.Style.FILL);p.setColor(Color.argb(150,8,31,55));c.drawRoundRect(l,238,r,388,12,12,p);
            p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(1);p.setColor(Color.rgb(25,82,120));c.drawRoundRect(l,238,r,388,12,12,p);
            drawPlane(c,(l+r)/2,286,.62f,i);
            text(c,ships[i],(l+r)/2,337,9,Color.WHITE,Paint.Align.CENTER);
        }
        button(c,25,442,W-25,505,"START  •  STAGE "+stage,true);
        text(c,"STAGE PROGRESS",W/2,545,12,Color.LTGRAY,Paint.Align.CENTER);
        text(c,"Every stage ends with a BOSS",W/2,570,15,Color.WHITE,Paint.Align.CENTER);
        text(c,"Boss defeated = stage cleared",W/2,595,12,Color.rgb(80,210,255),Paint.Align.CENTER);
        text(c,"COINS  "+coins,W-25,650,16,Color.YELLOW,Paint.Align.RIGHT);
        text(c,"GEMS  "+gems,W-25,678,16,Color.CYAN,Paint.Align.RIGHT);
        text(c,"20+ STAGES  •  BIG DROPS  •  EASY CONTROLS",W/2,H-78,10,Color.LTGRAY,Paint.Align.CENTER);
        text(c,"Ads only after boss defeat",W/2,H-52,10,Color.rgb(120,180,210),Paint.Align.CENTER);
    }

    void button(Canvas c,float l,float t,float r,float b,String s,boolean primary){
        p.setStyle(Paint.Style.FILL);p.setColor(primary?Color.rgb(8,88,125):Color.rgb(8,40,68));c.drawRoundRect(l,t,r,b,13,13,p);
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(primary?2:1);p.setColor(primary?Color.rgb(75,220,255):Color.rgb(45,135,180));c.drawRoundRect(l,t,r,b,13,13,p);
        text(c,s,(l+r)/2,t+(b-t)/2+7,16,Color.WHITE,Paint.Align.CENTER);
    }

    void startStage(){
        screen=PLAY; wave=0; enemiesKilled=0; enemiesTarget=8+Math.min(10,stage/2); bossSpawned=false; bossDefeated=false;
        enemies.clear();bullets.clear();drops.clear();spawnTimer=0;shotTimer=0;hp=Math.max(hp,60);shield=Math.min(shield,2);
        px=W/2f;py=H-170; last=System.currentTimeMillis();
    }

    void drawGame(Canvas c){
        bg(c);
        long now=System.currentTimeMillis(), elapsed=now-last; last=now;
        float dt=Math.min(.035f,elapsed/1000f);
        spawnTimer+=elapsed;shotTimer+=elapsed;
        for(Obj s:stars){s.y+=80*s.vy*dt;if(s.y>1800)s.y=0;}
        if(px==0){px=W/2f;py=H-170;}
        if(!bossSpawned){
            if(enemiesKilled<enemiesTarget){
                if(spawnTimer>520 && enemies.size()<8){spawnTimer=0;spawnEnemy();}
            } else if(enemies.isEmpty()) spawnBoss();
        }
        if(shotTimer>190){shotTimer=0;shoot();}
        update(dt); drawObjects(c); drawPlayer(c); hud(c);
        postInvalidateDelayed(16);
    }

    void spawnEnemy(){
        int t=rng.nextInt(6); Obj e=new Obj(40+rng.nextFloat()*(W-80),-55,18+rng.nextFloat()*9,t);
        e.vy=90+rng.nextFloat()*90; e.hp=1+stage/5; enemies.add(e);
    }

    void spawnBoss(){
        bossSpawned=true; bossMaxHp=50+stage*12;
        Obj b=new Obj(W/2f,-90,58,10);b.hp=bossMaxHp;b.vy=70;enemies.add(b);
    }

    void update(float dt){
        for(Obj b:bullets){b.y-=760*dt;if(b.y<-60)b.alive=false;}
        for(Obj e:enemies){
            e.y+=e.vy*dt;
            if(e.type==10){e.x=W/2f+(float)Math.sin(e.y*.009f)*W*.34f;e.vy= e.y<150?65:18;}
            else e.x+=Math.sin(e.y*.02f+e.type)*45*dt;
            if(e.y>H+80)e.alive=false;
        }
        for(Obj d:drops){d.y+=145*dt;if(d.y>H+60)d.alive=false;if(Math.hypot(d.x-px,d.y-py)<48){d.alive=false;collect(d.type);}}
        for(Obj b:bullets) if(b.alive) for(Obj e:enemies) if(e.alive&&Math.hypot(b.x-e.x,b.y-e.y)<e.r+10){
            b.alive=false;e.hp--; if(e.hp<=0){e.alive=false;killEnemy(e);}
        }
        for(Obj e:enemies) if(e.alive&&Math.hypot(e.x-px,e.y-py)<e.r+25){e.alive=false;if(shield>0)shield--;else hp-=12;}
        clean(bullets);clean(enemies);clean(drops);
        if(bossSpawned && enemies.isEmpty() && !bossDefeated){bossDefeated=true;score+=stage*10000;coins+=stage*250;gems+=stage;screen=CLEAR;clearTimer=0;}
        if(hp<=0)screen=DEAD;
    }

    void killEnemy(Obj e){
        if(e.type==10){return;}
        enemiesKilled++;score+=100+stage*15;coins+=5+stage;
        if(rng.nextFloat()<.95f) drops.add(new Obj(e.x,e.y,15,rng.nextInt(12)));
    }

    void collect(int t){
        if(t==0||t==2)power=Math.min(5,power+1); else if(t==1)power=Math.min(5,power+2); else if(t==3)shield=Math.min(3,shield+1);
        else if(t==5)hp=Math.min(100,hp+30); else if(t==6)coins+=100; else if(t==7)gems+=5; else if(t==8)score+=500; else if(t==9)bomb=Math.min(5,bomb+1); else if(t==10){for(Obj e:enemies)if(e.type!=10)e.hp-=10;} else if(t==11)power=5;
    }
    void clean(ArrayList<Obj>a){for(int i=a.size()-1;i>=0;i--)if(!a.get(i).alive)a.remove(i);}

    void shoot(){
        int n=power>=4?3:power>=2?2:1;
        for(int i=0;i<n;i++){float off=(i-(n-1)/2f)*16;bullets.add(new Obj(px+off,py-55,6,0));}
    }

    void drawObjects(Canvas c){for(Obj b:bullets)drawBullet(c,b);for(Obj e:enemies)drawEnemy(c,e);for(Obj d:drops)drawDrop(c,d);}
    void drawBullet(Canvas c,Obj b){p.setStyle(Paint.Style.FILL);p.setColor(Color.argb(70,40,220,255));c.drawOval(b.x-9,b.y-28,b.x+9,b.y+28,p);p.setColor(Color.WHITE);c.drawRoundRect(b.x-3,b.y-18,b.x+3,b.y+18,3,3,p);}

    void drawPlane(Canvas c,float x,float y,float sc,int variant){
        int col=shipColor[Math.floorMod(variant,5)];p.setStyle(Paint.Style.FILL);
        p.setColor(Color.argb(75,80,220,255));c.drawOval(x-9*sc,y+25*sc,x+9*sc,y+66*sc,p);
        p.setColor(Color.argb(170,255,150,45));c.drawOval(x-5*sc,y+27*sc,x+5*sc,y+53*sc,p);
        Path wing=new Path();wing.moveTo(x,y-8*sc);wing.lineTo(x+50*sc,y+25*sc);wing.lineTo(x+21*sc,y+22*sc);wing.lineTo(x+10*sc,y+38*sc);wing.lineTo(x,y+28*sc);wing.lineTo(x-10*sc,y+38*sc);wing.lineTo(x-21*sc,y+22*sc);wing.lineTo(x-50*sc,y+25*sc);wing.close();p.setColor(col);c.drawPath(wing,p);
        Path body=new Path();body.moveTo(x,y-53*sc);body.cubicTo(x+13*sc,y-35*sc,x+16*sc,y+15*sc,x+8*sc,y+45*sc);body.lineTo(x,y+57*sc);body.lineTo(x-8*sc,y+45*sc);body.cubicTo(x-16*sc,y+15*sc,x-13*sc,y-35*sc,x,y-53*sc);body.close();p.setColor(Color.rgb(225,235,245));c.drawPath(body,p);
        p.setColor(col);c.drawOval(x-7*sc,y-25*sc,x+7*sc,y+35*sc,p);p.setColor(Color.rgb(35,55,90));c.drawOval(x-7*sc,y-24*sc,x+7*sc,y-3*sc,p);
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(2*sc);p.setColor(Color.WHITE);c.drawLine(x-25*sc,y+22*sc,x-42*sc,y+27*sc,p);c.drawLine(x+25*sc,y+22*sc,x+42*sc,y+27*sc,p);p.setStrokeWidth(1);
    }
    void drawPlayer(Canvas c){drawPlane(c,px,py,1,ship);if(shield>0){p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(4);p.setColor(Color.argb(170,80,235,255));c.drawCircle(px,py,50,p);p.setStrokeWidth(1);}}
    void drawEnemy(Canvas c,Obj e){if(e.type==10){drawBoss(c,e);return;}float s=.72f;int col=enemyColor[e.type%enemyColor.length];p.setStyle(Paint.Style.FILL);Path w=new Path();w.moveTo(e.x,e.y-34*s);w.lineTo(e.x+45*s,e.y+22*s);w.lineTo(e.x+16*s,e.y+16*s);w.lineTo(e.x,e.y+35*s);w.lineTo(e.x-16*s,e.y+16*s);w.lineTo(e.x-45*s,e.y+22*s);w.close();p.setColor(col);c.drawPath(w,p);p.setColor(Color.rgb(65,75,105));c.drawOval(e.x-8*s,e.y-24*s,e.x+8*s,e.y+18*s,p);p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(1.5f);p.setColor(Color.WHITE);c.drawPath(w,p);}
    void drawBoss(Canvas c,Obj e){
        p.setStyle(Paint.Style.FILL);p.setColor(Color.rgb(55,25,85));c.drawOval(e.x-e.r,e.y-e.r*.55f,e.x+e.r,e.y+e.r*.55f,p);
        p.setColor(Color.rgb(150,50,145));c.drawOval(e.x-e.r*.72f,e.y-e.r*.36f,e.x+e.r*.72f,e.y+e.r*.36f,p);
        p.setColor(Color.rgb(40,210,220));c.drawOval(e.x-15,e.y-9,e.x+15,e.y+9,p);
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(3);p.setColor(Color.rgb(255,205,55));c.drawOval(e.x-e.r,e.y-e.r*.55f,e.x+e.r,e.y+e.r*.55f,p);
        float ratio=Math.max(0,e.hp)/(float)bossMaxHp; p.setStyle(Paint.Style.FILL);p.setColor(Color.DKGRAY);c.drawRoundRect(e.x-70,e.y-78,e.x+70,e.y-68,5,5,p);p.setColor(Color.rgb(255,70,100));c.drawRoundRect(e.x-70,e.y-78,e.x-70+140*ratio,e.y-68,5,5,p);
        text(c,"BOSS",e.x,e.y+e.r+22,12,Color.rgb(255,210,80),Paint.Align.CENTER);
    }
    void drawDrop(Canvas c,Obj d){String s=new String[]{"P","+","W","S","X","H","C","G","$","B","*","MAX"}[d.type%12];int col=d.type==7?Color.CYAN:d.type==6?Color.YELLOW:Color.rgb(80,230,255);p.setStyle(Paint.Style.FILL);p.setColor(Color.argb(190,8,30,55));c.drawCircle(d.x,d.y,17,p);p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(2);p.setColor(col);c.drawCircle(d.x,d.y,17,p);text(c,s,d.x,d.y+5,11,col,Paint.Align.CENTER);}

    void hud(Canvas c){
        p.setStyle(Paint.Style.FILL);p.setColor(Color.argb(190,3,10,24));c.drawRect(0,0,W,72,p);
        text(c,"STAGE "+stage,W/2,25,17,Color.WHITE,Paint.Align.CENTER);
        text(c,bossSpawned?"BOSS FIGHT":"WAVE "+Math.min(enemiesTarget,enemiesKilled)+" / "+enemiesTarget,W/2,48,11,bossSpawned?Color.rgb(255,100,110):Color.LTGRAY,Paint.Align.CENTER);
        text(c,"HP "+hp,W-14,24,13,Color.rgb(100,240,160),Paint.Align.RIGHT);text(c,"PWR "+power,W-14,45,11,Color.WHITE,Paint.Align.RIGHT);
        text(c,"S "+score,14,24,12,Color.WHITE,Paint.Align.LEFT);text(c,"C "+coins,14,45,11,Color.YELLOW,Paint.Align.LEFT);
    }

    void drawClear(Canvas c){
        bg(c);panel(c,20,170,W-20,600);
        text(c,"STAGE CLEAR",W/2,235,34,Color.rgb(90,240,180),Paint.Align.CENTER);
        text(c,"BOSS DEFEATED",W/2,270,17,Color.WHITE,Paint.Align.CENTER);
        text(c,"STAGE "+stage+" COMPLETE",W/2,315,20,Color.rgb(255,205,70),Paint.Align.CENTER);
        text(c,"+"+(stage*250)+" COINS",W/2,355,14,Color.YELLOW,Paint.Align.CENTER);
        text(c,"+"+stage+" GEMS",W/2,380,14,Color.CYAN,Paint.Align.CENTER);
        text(c,"Next stage is unlocked after the ad",W/2,430,12,Color.LTGRAY,Paint.Align.CENTER);
        button(c,35,465,W-35,530,"WATCH AD  •  NEXT STAGE",true);
        text(c,"No ads during shooting or boss battle",W/2,570,10,Color.rgb(110,180,210),Paint.Align.CENTER);
    }

    void drawDead(Canvas c){bg(c);panel(c,25,220,W-25,560);text(c,"MISSION FAILED",W/2,285,32,Color.rgb(255,90,110),Paint.Align.CENTER);text(c,"STAGE "+stage,W/2,325,17,Color.WHITE,Paint.Align.CENTER);text(c,"SCORE  "+score,W/2,360,14,Color.LTGRAY,Paint.Align.CENTER);button(c,45,410,W-45,475,"RETRY STAGE",true);button(c,45,490,W-45,550,"MAIN MENU",false);}

    void launchAd(){
        if(adPending)return;
        adPending=true;adLaunchedAt=System.currentTimeMillis();
        try{Intent i=new Intent(Intent.ACTION_VIEW, Uri.parse(MONETAG_URL));getContext().startActivity(i);}catch(Exception ignored){adPending=false;startNextStage();}
    }
    public void onAdReturn(){
        if(!adPending)return;
        if(System.currentTimeMillis()-adLaunchedAt<800)return;
        adPending=false;startNextStage();
    }
    void startNextStage(){stage++;screen=MENU;bossSpawned=false;bossDefeated=false;invalidate();}

    @Override public boolean onTouchEvent(android.view.MotionEvent e){
        float x=e.getX(),y=e.getY();
        if(e.getAction()==MotionEvent.ACTION_DOWN){
            if(screen==MENU && y>430&&y<525){ship=Math.max(0,Math.min(4,(int)((x-18)/((W-36)/5f))));startStage();return true;}
            if(screen==CLEAR && y>455&&y<545){launchAd();return true;}
            if(screen==DEAD && y>400&&y<485){startStage();return true;}
            if(screen==DEAD && y>485&&y<565){screen=MENU;invalidate();return true;}
            touchMove=true;
        }
        if(screen==PLAY && touchMove && (e.getAction()==MotionEvent.ACTION_MOVE||e.getAction()==MotionEvent.ACTION_DOWN)){
            px=Math.max(35,Math.min(W-35,x));py=Math.max(105,Math.min(H-80,y));return true;
        }
        if(e.getAction()==MotionEvent.ACTION_UP)touchMove=false;
        return true;
    }
}
