package com.skywings.reborn;

import android.content.Context;
import android.graphics.*;
import android.graphics.drawable.*;
import android.view.*;
import java.util.*;

public class GameView extends View {
    static class Obj { float x,y,vx,vy,r; int type, hp; boolean alive=true; Obj(float X,float Y,float R,int T){x=X;y=Y;r=R;type=T;} }
    Paint p=new Paint(3); Random rng=new Random(); ArrayList<Obj> enemies=new ArrayList<>(), bullets=new ArrayList<>(), drops=new ArrayList<>(), stars=new ArrayList<>();
    int screen=0, stage=1, score=235680, coins=2356, gems=156, hp=100, power=1, shield=0, bomb=3; float px,py; long last, spawn, shotTimer;
    int W,H; boolean dragging=false; String[] planes={"FALCON","VIPER","PHANTOM","TYPHOON","AEGIS"};
    GameView(Context c){super(c); p.setTypeface(Typeface.create("sans",0)); for(int i=0;i<100;i++) stars.add(new Obj(rng.nextInt(1000),rng.nextInt(1800),rng.nextFloat()*2+1,0)); setFocusable(true); last=System.currentTimeMillis();}
    void txt(Canvas c,String s,float x,float y,float size,int color,Paint.Align a){p.setStyle(Paint.Style.FILL);p.setTextSize(size);p.setColor(color);p.setTextAlign(a);p.setTypeface(Typeface.create("sans",Typeface.BOLD));c.drawText(s,x,y,p);}
    void panel(Canvas c,float l,float t,float r,float b){p.setStyle(Paint.Style.FILL);p.setColor(Color.argb(225,3,15,29));c.drawRoundRect(l,t,r,b,12,12,p);p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(1.5f);p.setColor(Color.rgb(35,154,220));c.drawRoundRect(l,t,r,b,12,12,p);}
    @Override protected void onDraw(Canvas c){W=getWidth();H=getHeight(); if(screen==1) drawGame(c); else drawMenu(c);}
    void bg(Canvas c){c.drawColor(Color.rgb(2,7,17)); p.setStyle(Paint.Style.FILL); for(Obj s:stars){p.setColor(Color.argb(150,90,190,255));c.drawCircle(s.x/1000f*W,s.y/1800f*H,s.r,p);} }
    void drawMenu(Canvas c){bg(c); txt(c,"✦ ✦ ✦",W/2,70,26,Color.YELLOW,Paint.Align.CENTER); txt(c,"SKY WINGS",W/2,135,54,Color.rgb(105,205,255),Paint.Align.CENTER); txt(c,"1942 REBORN",W/2,170,22,Color.rgb(255,177,35),Paint.Align.CENTER);
        panel(c,16,195,W-16,H-25); txt(c,"เครื่องบินของผู้เล่น",35,230,22,Color.WHITE,Paint.Align.LEFT);
        for(int i=0;i<5;i++){float l=25+i*(W-50)/5f,r=25+(i+1)*(W-50)/5f; p.setStyle(Paint.Style.STROKE);p.setColor(Color.rgb(20,73,108));c.drawRect(l,245,r,405,p); drawPlane(c,(l+r)/2,315,1,i);txt(c,planes[i],(l+r)/2,355,15,Color.WHITE,Paint.Align.CENTER);txt(c,new String[]{"สมดุลทุกด้าน","พลังโจมตีสูง","ความเร็วสูง","ยิงกระจายรอบทิศ","มีโล่ป้องกัน"}[i],(l+r)/2,378,10,Color.LTGRAY,Paint.Align.CENTER);}
        button(c,35,430,W-35,490,"START  •  ด่าน "+stage); button(c,35,505,W-35,565,"UPGRADE");button(c,35,580,W-35,640,"SHOP");button(c,35,655,W-35,715,"MISSION");
        txt(c,"💰 "+coins,W-30,755,18,Color.YELLOW,Paint.Align.RIGHT);txt(c,"💎 "+gems,W-30,780,18,Color.CYAN,Paint.Align.RIGHT);
        txt(c,"ไอเท็มดรอปเยอะ • เล่นง่าย • บอสทุก 5 ด่าน",W/2,825,14,Color.LTGRAY,Paint.Align.CENTER);
    }
    void button(Canvas c,float l,float t,float r,float b,String s){p.setStyle(Paint.Style.FILL);p.setColor(Color.rgb(8,45,78));c.drawRoundRect(l,t,r,b,10,10,p);p.setStyle(Paint.Style.STROKE);p.setColor(Color.rgb(55,180,240));c.drawRoundRect(l,t,r,b,10,10,p);txt(c,s,(l+r)/2,t+39,19,Color.WHITE,Paint.Align.CENTER);}
    void drawGame(Canvas c){bg(c); long now=System.currentTimeMillis(); float dt=Math.min(0.035f,(now-last)/1000f);last=now; for(Obj s:stars){s.y+=80*dt;if(s.y>1800)s.y=0;}
        if(px==0){px=W/2;py=H-180;}
        spawn+=now-last; shotTimer+=now-last; if(spawn>650 && enemies.size()<12){spawn=0;spawnEnemy();} if(shotTimer>180){shotTimer=0;shoot();}
        updateObjects(dt); drawObjects(c); drawPlayer(c); hud(c); if(hp<=0){screen=2;}
        postInvalidateDelayed(16);
    }
    void spawnEnemy(){int t=rng.nextInt(6); Obj e=new Obj(40+rng.nextFloat()*(W-80),-40,18+rng.nextFloat()*10,t);e.vy=70+rng.nextFloat()*80;e.hp=1+(stage/4);if(stage%5==0&&rng.nextFloat()<.12){e.type=10;e.r=48;e.hp=30+stage*3;}enemies.add(e);}
    void updateObjects(float dt){for(Obj b:bullets){b.y-=650*dt;if(b.y<-40)b.alive=false;} for(Obj e:enemies){e.y+=e.vy*dt;e.x+=Math.sin(e.y*.025)*35*dt;if(e.type==10)e.x+=Math.sin(e.y*.01)*80*dt;if(e.y>H+60)e.alive=false;}
        for(Obj d:drops){d.y+=130*dt;if(d.y>H+50)d.alive=false; if(Math.hypot(d.x-px,d.y-py)<42){d.alive=false; collect(d.type);}}
        for(Obj b:bullets) if(b.alive) for(Obj e:enemies) if(e.alive && Math.hypot(b.x-e.x,b.y-e.y)<e.r+7){b.alive=false;e.hp--; if(e.hp<=0){e.alive=false;score+=e.type==10?5000:100;coins+=e.type==10?100:5;if(rng.nextFloat()<.82)drops.add(new Obj(e.x,e.y,15,rng.nextInt(12)));}}
        for(Obj e:enemies) if(e.alive&&Math.hypot(e.x-px,e.y-py)<e.r+25){e.alive=false;if(shield>0)shield--;else hp-=10;}
        clean(bullets);clean(enemies);clean(drops);
    }
    void clean(ArrayList<Obj> a){for(int i=a.size()-1;i>=0;i--)if(!a.get(i).alive)a.remove(i);}
    void collect(int t){if(t==0){power=Math.min(5,power+1);}else if(t==1){power=Math.min(5,power+2);}else if(t==2){power=Math.min(5,power+1);}else if(t==3){shield=Math.min(3,shield+1);}else if(t==5){hp=Math.min(100,hp+25);}else if(t==6){coins+=100;}else if(t==7){gems+=5;}else if(t==8){score+=500;}else if(t==9){bomb=Math.min(5,bomb+1);}else if(t==10){for(Obj e:enemies)e.hp-=10;}else if(t==11){power=5;}}
    void drawObjects(Canvas c){for(Obj b:bullets){p.setStyle(Paint.Style.FILL);p.setColor(Color.CYAN);c.drawOval(b.x-4,b.y-20,b.x+4,b.y+20,p);}for(Obj e:enemies){drawEnemy(c,e); } for(Obj d:drops){drawDrop(c,d);}}
    void drawPlayer(Canvas c){drawPlane(c,px,py,1,0);if(shield>0){p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(4);p.setColor(Color.CYAN);c.drawCircle(px,py,42,p);}}
    void drawPlane(Canvas c,float x,float y,float sc,int variant){Path q=new Path();q.moveTo(x,y-42*sc);q.lineTo(x+14*sc,y-12*sc);q.lineTo(x+42*sc,y+20*sc);q.lineTo(x+13*sc,y+14*sc);q.lineTo(x,y+44*sc);q.lineTo(x-13*sc,y+14*sc);q.lineTo(x-42*sc,y+20*sc);q.lineTo(x-14*sc,y-12*sc);q.close();p.setStyle(Paint.Style.FILL);int[] cols={Color.rgb(60,180,255),Color.rgb(255,70,55),Color.rgb(255,190,30),Color.rgb(175,70,255),Color.rgb(210,240,255)};p.setColor(cols[variant%5]);c.drawPath(q,p);p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(2);p.setColor(Color.WHITE);c.drawPath(q,p);p.setStyle(Paint.Style.FILL);p.setColor(Color.WHITE);c.drawCircle(x,y-5,6*sc,p);p.setColor(Color.rgb(30,70,120));c.drawCircle(x,y-5,3*sc,p);}
    void drawEnemy(Canvas c,Obj e){if(e.type==10){p.setStyle(Paint.Style.FILL);p.setColor(Color.rgb(100,55,35));c.drawOval(e.x-e.r,e.y-e.r*.55f,e.x+e.r,e.y+e.r*.55f,p);p.setStyle(Paint.Style.STROKE);p.setColor(Color.YELLOW);p.setStrokeWidth(3);c.drawOval(e.x-e.r,e.y-e.r*.55f,e.x+e.r,e.y+e.r*.55f,p);txt(c,"BOSS",e.x,e.y+5,12,Color.WHITE,Paint.Align.CENTER);return;} drawPlane(c,e.x,e.y,-1,(e.type+1)%5);}
    void drawDrop(Canvas c,Obj d){String[] s={"✦","Ⅱ","▲","◇","✚","♥","$","◆","★","B","⚡","●"};int[] col={Color.WHITE,Color.RED,Color.GREEN,Color.MAGENTA,Color.CYAN,Color.RED,Color.YELLOW,Color.CYAN,Color.YELLOW,Color.rgb(255,130,20),Color.CYAN,Color.rgb(255,80,220)};p.setStyle(Paint.Style.FILL);p.setColor(Color.argb(90, Color.red(col[d.type]), Color.green(col[d.type]), Color.blue(col[d.type])));c.drawCircle(d.x,d.y,20,p);txt(c,s[d.type],d.x,d.y+7,24,col[d.type],Paint.Align.CENTER);}
    void hud(Canvas c){p.setStyle(Paint.Style.FILL);p.setColor(Color.argb(210,0,0,0));c.drawRect(0,0,W,70,p);txt(c,"HP",18,27,14,Color.WHITE,Paint.Align.LEFT);p.setColor(Color.DKGRAY);c.drawRect(55,15,220,29,p);p.setColor(Color.rgb(255,190,30));c.drawRect(55,15,55+165*hp/100f,29,p);txt(c,hp+"%",230,28,13,Color.WHITE,Paint.Align.LEFT);txt(c,String.format("%08d",score),W-18,28,18,Color.WHITE,Paint.Align.RIGHT);txt(c,"💰"+coins+"   💎"+gems,W-18,54,13,Color.LTGRAY,Paint.Align.RIGHT);txt(c,"POWER ×"+power,W/2,55,15,Color.CYAN,Paint.Align.CENTER);txt(c,"BOMB "+bomb,W-18,H-25,14,Color.YELLOW,Paint.Align.RIGHT);}
    @Override public boolean onTouchEvent(android.view.MotionEvent ev){float x=ev.getX(),y=ev.getY();if(ev.getAction()==MotionEvent.ACTION_DOWN){if(screen==0){if(y>420&&y<500){screen=1;invalidate();return true;} if(y>500&&y<570){coins+=0;return true;}} else if(screen==1){dragging=true;px=x;py=Math.max(100,Math.min(H-80,y));shoot();}else if(screen==2){screen=0;hp=100;invalidate();}return true;} if(ev.getAction()==MotionEvent.ACTION_MOVE&&screen==1&&dragging){px=Math.max(35,Math.min(W-35,x));py=Math.max(90,Math.min(H-90,y));return true;}if(ev.getAction()==MotionEvent.ACTION_UP){dragging=false;if(screen==1&&x>W-110&&y>H-90&&bomb>0){bomb--;for(Obj e:enemies)e.hp-=20;}}return true;}
    void shoot(){int n=power>=4?5:power>=2?3:1;for(int i=0;i<n;i++){Obj b=new Obj(px+(i-(n-1)/2f)*12,py-48,4,0);b.vy=-1;bullets.add(b);}}
}
