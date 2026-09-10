package com.skywings.reborn;

import android.content.Context;
import android.graphics.*;
import android.view.*;
import java.util.*;

public class GameView extends View {
    static class Obj { float x,y,vx,vy,r; int type,hp; boolean alive=true; Obj(float X,float Y,float R,int T){x=X;y=Y;r=R;type=T;} }

    final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);
    final Random rng=new Random();
    final ArrayList<Obj> enemies=new ArrayList<>(), bullets=new ArrayList<>(), drops=new ArrayList<>(), stars=new ArrayList<>();
    final String[] planes={"FALCON","VIPER","PHANTOM","TYPHOON","AEGIS"};
    final int[] planeA={Color.rgb(60,205,255),Color.rgb(255,82,92),Color.rgb(255,190,55),Color.rgb(188,92,255),Color.rgb(220,245,255)};
    final int[] enemyA={Color.rgb(255,80,90),Color.rgb(255,155,45),Color.rgb(185,80,255),Color.rgb(65,230,190),Color.rgb(70,155,255),Color.rgb(255,80,190)};

    int screen=0, stage=1, score=235680, coins=2356, gems=156, hp=100, power=1, shield=0, bomb=3;
    float px,py; long last, spawnTimer, shotTimer; int W,H; boolean dragging=false;

    public GameView(Context c){
        super(c); setFocusable(true); last=System.currentTimeMillis();
        for(int i=0;i<120;i++){ Obj s=new Obj(rng.nextInt(1000),rng.nextInt(1800),rng.nextFloat()*2.4f+.5f,0); s.vy=.35f+rng.nextFloat()*1.5f; stars.add(s); }
    }

    void txt(Canvas c,String s,float x,float y,float size,int color,Paint.Align a){
        p.setStyle(Paint.Style.FILL);p.setColor(color);p.setTextSize(size);p.setTextAlign(a);p.setTypeface(Typeface.create("sans",Typeface.BOLD));c.drawText(s,x,y,p);
    }
    void panel(Canvas c,float l,float t,float r,float b){
        p.setStyle(Paint.Style.FILL);p.setColor(Color.argb(225,5,14,31));c.drawRoundRect(l,t,r,b,18,18,p);
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(1.5f);p.setColor(Color.rgb(35,150,220));c.drawRoundRect(l,t,r,b,18,18,p);
    }
    void bg(Canvas c){
        c.drawColor(Color.rgb(2,6,18));
        for(Obj s:stars){
            float sx=s.x/1000f*W, sy=s.y/1800f*H;
            p.setStyle(Paint.Style.FILL);p.setColor(Color.argb(80+(int)(s.vy*45),120,210,255));
            c.drawCircle(sx,sy,s.r,p);
        }
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(1);p.setColor(Color.argb(22,80,170,255));
        for(int y=100;y<H;y+=140)c.drawLine(0,y,W,y,p);
    }

    @Override protected void onDraw(Canvas c){ W=getWidth(); H=getHeight(); if(screen==1) drawGame(c); else drawMenu(c); }

    void drawMenu(Canvas c){
        bg(c);
        txt(c,"✦  ✦  ✦",W/2,58,20,Color.rgb(80,210,255),Paint.Align.CENTER);
        txt(c,"SKY WINGS",W/2,118,50,Color.WHITE,Paint.Align.CENTER);
        txt(c,"1942  REBORN",W/2,151,19,Color.rgb(255,183,45),Paint.Align.CENTER);
        txt(c,"NEON SKY ARCADE",W/2,176,11,Color.rgb(90,190,225),Paint.Align.CENTER);

        panel(c,12,195,W-12,430);
        txt(c,"CHOOSE YOUR FIGHTER",W/2,224,16,Color.WHITE,Paint.Align.CENTER);
        float gap=7, left=18, cardW=(W-36-gap*4)/5f;
        for(int i=0;i<5;i++){
            float l=left+i*(cardW+gap), r=l+cardW;
            p.setStyle(Paint.Style.FILL);p.setColor(Color.argb(150,8,31,55));c.drawRoundRect(l,240,r,393,12,12,p);
            p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(1);p.setColor(Color.rgb(25,82,120));c.drawRoundRect(l,240,r,393,12,12,p);
            drawPlane(c,(l+r)/2,292,0.72f,i);
            txt(c,planes[i],(l+r)/2,342,10,Color.WHITE,Paint.Align.CENTER);
            txt(c,new String[]{"BALANCED","POWER","SPEED","SPREAD","SHIELD"}[i],(l+r)/2,358,8,Color.LTGRAY,Paint.Align.CENTER);
        }

        button(c,25,450,W-25,510,"START  •  STAGE "+stage,true);
        button(c,25,522,W-25,577,"UPGRADE",false);
        button(c,25,589,W-25,644,"SHOP",false);
        button(c,25,656,W-25,711,"MISSIONS",false);
        txt(c,"💰 "+coins,W-25,750,17,Color.YELLOW,Paint.Align.RIGHT);
        txt(c,"💎 "+gems,W-25,775,17,Color.CYAN,Paint.Align.RIGHT);
        txt(c,"EASY TO PLAY  •  BIG DROPS  •  BOSS EVERY 5 STAGES",W/2,825,11,Color.LTGRAY,Paint.Align.CENTER);
        drawAdSlot(c,18,H-75,W-18,H-16,"OPTIONAL AD • FREE REWARD");
    }

    void button(Canvas c,float l,float t,float r,float b,String s,boolean primary){
        p.setStyle(Paint.Style.FILL);p.setColor(primary?Color.rgb(8,88,125):Color.rgb(8,40,68));c.drawRoundRect(l,t,r,b,13,13,p);
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(primary?2:1);p.setColor(primary?Color.rgb(75,220,255):Color.rgb(45,135,180));c.drawRoundRect(l,t,r,b,13,13,p);
        txt(c,s,(l+r)/2,t+(b-t)/2+7,17,Color.WHITE,Paint.Align.CENTER);
    }

    void drawAdSlot(Canvas c,float l,float t,float r,float b,String label){
        // Reserved, non-blocking ad area. Actual SDK can be attached later without changing gameplay layout.
        p.setStyle(Paint.Style.FILL);p.setColor(Color.argb(115,10,20,32));c.drawRoundRect(l,t,r,b,10,10,p);
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(1);p.setColor(Color.argb(80,100,160,190));c.drawRoundRect(l,t,r,b,10,10,p);
        txt(c,label,(l+r)/2,(t+b)/2+4,10,Color.rgb(125,155,175),Paint.Align.CENTER);
    }

    void drawGame(Canvas c){
        bg(c);
        long now=System.currentTimeMillis(); long elapsed=now-last; last=now;
        float dt=Math.min(0.035f,elapsed/1000f);
        spawnTimer+=elapsed; shotTimer+=elapsed;
        for(Obj s:stars){s.y+=80*s.vy*dt;if(s.y>1800)s.y=0;}
        if(px==0){px=W/2f;py=H-180;}
        if(spawnTimer>620 && enemies.size()<14){spawnTimer=0;spawnEnemy();}
        if(shotTimer>210){shotTimer=0;shoot();}
        updateObjects(dt); drawObjects(c); drawPlayer(c); hud(c);
        if(hp<=0){screen=2;}
        postInvalidateDelayed(16);
    }

    void spawnEnemy(){
        int t=rng.nextInt(6); Obj e=new Obj(45+rng.nextFloat()*(W-90),-55,20+rng.nextFloat()*10,t);
        e.vy=80+rng.nextFloat()*85;e.hp=1+stage/4;
        if(stage%5==0 && rng.nextFloat()<.16f){e.type=10;e.r=52;e.hp=35+stage*3;}
        enemies.add(e);
    }

    void updateObjects(float dt){
        for(Obj b:bullets){b.y-=700*dt;if(b.y<-50)b.alive=false;}
        for(Obj e:enemies){
            e.y+=e.vy*dt;e.x+=Math.sin(e.y*.022f)*45*dt;
            if(e.type==10)e.x+=Math.sin(e.y*.008f)*95*dt;
            if(e.y>H+70)e.alive=false;
        }
        for(Obj d:drops){
            d.y+=135*dt;if(d.y>H+50)d.alive=false;
            if(Math.hypot(d.x-px,d.y-py)<44){d.alive=false;collect(d.type);}
        }
        for(Obj b:bullets) if(b.alive) for(Obj e:enemies) if(e.alive && Math.hypot(b.x-e.x,b.y-e.y)<e.r+9){
            b.alive=false;e.hp--; if(e.hp<=0){e.alive=false;score+=e.type==10?5000:100;coins+=e.type==10?100:5;if(rng.nextFloat()<.88f)drops.add(new Obj(e.x,e.y,15,rng.nextInt(12)));}
        }
        for(Obj e:enemies) if(e.alive&&Math.hypot(e.x-px,e.y-py)<e.r+27){e.alive=false;if(shield>0)shield--;else hp-=10;}
        clean(bullets);clean(enemies);clean(drops);
    }
    void clean(ArrayList<Obj> a){for(int i=a.size()-1;i>=0;i--)if(!a.get(i).alive)a.remove(i);}
    void collect(int t){
        if(t==0||t==2)power=Math.min(5,power+1);else if(t==1)power=Math.min(5,power+2);else if(t==3)shield=Math.min(3,shield+1);
        else if(t==5)hp=Math.min(100,hp+25);else if(t==6)coins+=100;else if(t==7)gems+=5;else if(t==8)score+=500;else if(t==9)bomb=Math.min(5,bomb+1);else if(t==10){for(Obj e:enemies)e.hp-=10;}else if(t==11)power=5;
    }

    void drawObjects(Canvas c){for(Obj b:bullets)drawBullet(c,b);for(Obj e:enemies)drawEnemy(c,e);for(Obj d:drops)drawDrop(c,d);}
    void drawBullet(Canvas c,Obj b){
        p.setStyle(Paint.Style.FILL);p.setColor(Color.argb(70,40,220,255));c.drawOval(b.x-9,b.y-28,b.x+9,b.y+28,p);
        p.setColor(Color.WHITE);c.drawRoundRect(b.x-3,b.y-18,b.x+3,b.y+18,3,3,p);
    }

    void drawPlayer(Canvas c){drawPlane(c,px,py,1f,0);if(shield>0){p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(4);p.setColor(Color.argb(170,80,235,255));c.drawCircle(px,py,48,p);p.setStrokeWidth(1);}}

    // Original futuristic arcade fighter: no real-world aircraft branding.
    void drawPlane(Canvas c,float x,float y,float sc,int variant){
        int col=planeA[Math.floorMod(variant,5)];
        p.setStyle(Paint.Style.FILL);
        // engine glow
        p.setColor(Color.argb(80,80,220,255));c.drawOval(x-9*sc,y+25*sc,x+9*sc,y+66*sc,p);
        p.setColor(Color.argb(170,255,150,45));c.drawOval(x-5*sc,y+27*sc,x+5*sc,y+53*sc,p);
        // wings
        Path wing=new Path();wing.moveTo(x,y-8*sc);wing.lineTo(x+50*sc,y+25*sc);wing.lineTo(x+21*sc,y+22*sc);wing.lineTo(x+10*sc,y+38*sc);wing.lineTo(x,y+28*sc);wing.lineTo(x-10*sc,y+38*sc);wing.lineTo(x-21*sc,y+22*sc);wing.lineTo(x-50*sc,y+25*sc);wing.close();
        p.setColor(col);c.drawPath(wing,p);
        // fuselage
        Path body=new Path();body.moveTo(x,y-53*sc);body.cubicTo(x+13*sc,y-35*sc,x+16*sc,y+15*sc,x+8*sc,y+45*sc);body.lineTo(x,y+57*sc);body.lineTo(x-8*sc,y+45*sc);body.cubicTo(x-16*sc,y+15*sc,x-13*sc,y-35*sc,x,y-53*sc);body.close();
        p.setColor(Color.rgb(225,235,245));c.drawPath(body,p);
        // colored armor center
        Path armor=new Path();armor.moveTo(x,y-45*sc);armor.lineTo(x+8*sc,y-15*sc);armor.lineTo(x+7*sc,y+28*sc);armor.lineTo(x,y+43*sc);armor.lineTo(x-7*sc,y+28*sc);armor.lineTo(x-8*sc,y-15*sc);armor.close();p.setColor(col);c.drawPath(armor,p);
        // cockpit
        p.setColor(Color.rgb(35,55,90));c.drawOval(x-7*sc,y-24*sc,x+7*sc,y-3*sc,p);p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(1.5f);p.setColor(Color.WHITE);c.drawOval(x-7*sc,y-24*sc,x+7*sc,y-3*sc,p);
        // wing weapons / highlights
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(2*sc);p.setColor(Color.WHITE);c.drawLine(x-25*sc,y+22*sc,x-42*sc,y+27*sc,p);c.drawLine(x+25*sc,y+22*sc,x+42*sc,y+27*sc,p);
        p.setStrokeWidth(1);p.setColor(Color.argb(170,255,255,255));c.drawLine(x,y-43*sc,x,y+35*sc,p);
    }

    void drawEnemy(Canvas c,Obj e){
        if(e.type==10){drawBoss(c,e);return;}
        float s=-.72f;int col=enemyA[e.type%enemyA.length];
        p.setStyle(Paint.Style.FILL);
        Path w=new Path();w.moveTo(e.x,e.y-34*s);w.lineTo(e.x+45*s,e.y+22*s);w.lineTo(e.x+16*s,e.y+16*s);w.lineTo(e.x,e.y+35*s);w.lineTo(e.x-16*s,e.y+16*s);w.lineTo(e.x-45*s,e.y+22*s);w.close();p.setColor(col);c.drawPath(w,p);
        Path b=new Path();b.moveTo(e.x,e.y-42*s);b.lineTo(e.x+10*s,e.y-8*s);b.lineTo(e.x+8*s,e.y+38*s);b.lineTo(e.x,e.y+46*s);b.lineTo(e.x-8*s,e.y+38*s);b.lineTo(e.x-10*s,e.y-8*s);b.close();p.setColor(Color.rgb(65,75,105));c.drawPath(b,p);
        p.setColor(col);c.drawOval(e.x-6*s,e.y-22*s,e.x+6*s,e.y-5*s,p);
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(1.5f);p.setColor(Color.WHITE);c.drawPath(w,p);
    }
    void drawBoss(Canvas c,Obj e){
        p.setStyle(Paint.Style.FILL);p.setColor(Color.rgb(75,28,85));c.drawOval(e.x-e.r,e.y-e.r*.55f,e.x+e.r,e.y+e.r*.55f,p);
        p.setColor(Color.rgb(155,55,145));c.drawOval(e.x-e.r*.72f,e.y-e.r*.36f,e.x+e.r*.72f,e.y+e.r*.36f,p);
        p.setColor(Color.rgb(40,210,220));c.drawOval(e.x-13,e.y-8,e.x+13,e.y+8,p);
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(3);p.setColor(Color.rgb(255,205,55));c.drawOval(e.x-e.r,e.y-e.r*.55f,e.x+e.r,e.y+e.r*.55f,p);
        txt(c,"BOSS",e.x,e.y+5,12,Color.WHITE,Paint.Align.CENTER);
    }

    void drawDrop(Canvas c,Obj d){
        int[] colors={Color.WHITE,Color.RED,Color.GREEN,Color.MAGENTA,Color.CYAN,Color.RED,Color.YELLOW,Color.CYAN,Color.YELLOW,Color.rgb(255,130,20),Color.CYAN,Color.rgb(255,80,220)};
        String[] symbols={"✦","Ⅱ","▲","◇","✚","♥","$","◆","★","B","⚡","●"};int cc=colors[d.type];
        p.setStyle(Paint.Style.FILL);p.setColor(Color.argb(45,Color.red(cc),Color.green(cc),Color.blue(cc)));c.drawCircle(d.x,d.y,25,p);
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(1.5f);p.setColor(Color.argb(180,Color.red(cc),Color.green(cc),Color.blue(cc)));c.drawCircle(d.x,d.y,21,p);
        txt(c,symbols[d.type],d.x,d.y+7,23,cc,Paint.Align.CENTER);
    }

    void hud(Canvas c){
        // Safe top HUD: never overlaps the play field controls.
        p.setStyle(Paint.Style.FILL);p.setColor(Color.argb(220,2,9,22));c.drawRect(0,0,W,74,p);
        txt(c,"HP",16,25,12,Color.WHITE,Paint.Align.LEFT);
        p.setColor(Color.DKGRAY);c.drawRoundRect(48,13,190,27,7,7,p);p.setColor(Color.rgb(55,225,145));c.drawRoundRect(48,13,48+142*hp/100f,27,7,7,p);
        txt(c,hp+"%",198,25,12,Color.WHITE,Paint.Align.LEFT);
        txt(c,String.format("%08d",score),W-16,25,17,Color.WHITE,Paint.Align.RIGHT);
        txt(c,"STAGE "+stage,W/2,25,12,Color.rgb(255,190,55),Paint.Align.CENTER);
        txt(c,"POWER ×"+power,W/2,56,14,Color.CYAN,Paint.Align.CENTER);
        txt(c,"💰"+coins+"  💎"+gems,W-16,53,12,Color.LTGRAY,Paint.Align.RIGHT);
        // Bomb control sits in a dedicated corner and never blocks the aircraft path.
        p.setStyle(Paint.Style.FILL);p.setColor(Color.argb(180,5,20,35));c.drawRoundRect(W-96,H-86,W-12,H-18,16,16,p);
        txt(c,"BOMB",W-54,H-57,10,Color.YELLOW,Paint.Align.CENTER);txt(c,""+bomb,W-54,H-32,17,Color.WHITE,Paint.Align.CENTER);
        // Deliberately empty lower-left safe zone for future rewarded-ad button / SDK overlay.
        drawAdSlot(c,12,H-55,W-112,H-18,"REWARD AD (OPTIONAL)");
    }

    @Override public boolean onTouchEvent(MotionEvent ev){
        float x=ev.getX(),y=ev.getY();
        if(ev.getAction()==MotionEvent.ACTION_DOWN){
            if(screen==0){if(y>440&&y<520){screen=1;px=0;invalidate();return true;}}
            else if(screen==1){dragging=true;px=x;py=Math.max(95,Math.min(H-105,y));shoot();}
            else if(screen==2){screen=0;hp=100;power=1;invalidate();}
            return true;
        }
        if(ev.getAction()==MotionEvent.ACTION_MOVE&&screen==1&&dragging){px=Math.max(38,Math.min(W-38,x));py=Math.max(90,Math.min(H-100,y));return true;}
        if(ev.getAction()==MotionEvent.ACTION_UP){
            dragging=false;
            if(screen==1&&x>W-110&&y>H-100&&bomb>0){bomb--;for(Obj e:enemies)e.hp-=20;}
        }
        return true;
    }

    void shoot(){
        int n=power>=4?5:power>=2?3:1;
        for(int i=0;i<n;i++){Obj b=new Obj(px+(i-(n-1)/2f)*14,py-48,4,0);bullets.add(b);}
    }
}
