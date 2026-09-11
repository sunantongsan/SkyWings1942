package com.skywings.reborn;

import android.content.Context;
import android.content.Intent;
import android.graphics.*;
import android.net.Uri;
import android.view.MotionEvent;
import android.view.View;
import java.util.ArrayList;
import java.util.Random;

public class GameView extends View {
    private static final String MONETAG_URL = "https://omg10.com/4/10852115";
    private static final int MENU=0, PLAY=1, DEAD=2, CLEAR=3;

    private static class Obj {
        float x,y,vx,vy,r,rot;
        int type,hp,maxHp;
        boolean alive=true;
        Obj(float x,float y,float r,int type){this.x=x;this.y=y;this.r=r;this.type=type;}
    }
    private static class Fx {
        float x,y,vx,vy,life,maxLife,size;
        int color;
        Fx(float x,float y,float vx,float vy,float life,float size,int color){
            this.x=x;this.y=y;this.vx=vx;this.vy=vy;this.life=life;this.maxLife=life;this.size=size;this.color=color;
        }
    }

    private final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Random rnd=new Random();
    private final ArrayList<Obj> enemies=new ArrayList<>();
    private final ArrayList<Obj> shots=new ArrayList<>();
    private final ArrayList<Obj> enemyShots=new ArrayList<>();
    private final ArrayList<Obj> drops=new ArrayList<>();
    private final ArrayList<Obj> stars=new ArrayList<>();
    private final ArrayList<Fx> fx=new ArrayList<>();

    private final String[] shipNames={"NOVA","RAPTOR","PHANTOM","TITAN","SERAPH"};
    private final int[] shipColors={
            Color.rgb(55,230,255),
            Color.rgb(255,72,115),
            Color.rgb(255,190,55),
            Color.rgb(178,95,255),
            Color.rgb(225,250,255)
    };
    private final int[] enemyColors={
            Color.rgb(255,68,98),
            Color.rgb(255,142,45),
            Color.rgb(184,70,255),
            Color.rgb(45,225,190),
            Color.rgb(65,150,255),
            Color.rgb(255,65,195)
    };

    private int mode=MENU, stage=1, ship=0, score=0, coins=0, gems=0;
    private int hp=100, power=1, shield=1, bombs=2, kills=0, target=10;
    private int W,H;
    private float px,py;
    private boolean bossActive=false, bombFlash=false, dragging=false, bossDying=false;
    private long last, spawnClock, shotClock, enemyShotClock, bombClock, bossDeathClock, lastBossBurstClock;
    private float touchAnchorX,touchAnchorY,shipAnchorX,shipAnchorY;
    private Bitmap playerAtlas, enemyBossAtlas, menuHd;
    private static final int[][] PLAYER_SRC={{3,0,53,80},{53,0,103,80},{103,0,153,80},{153,0,203,80},{203,0,253,80}};
    private static final int[][] ENEMY_SRC={{4,83,44,143},{45,83,85,143},{86,83,126,143},{127,83,167,143},{168,83,208,143},{209,83,249,143}};
    private static final int[][] BOSS_SRC={{1,148,85,255},{86,148,170,255},{171,148,255,255}};

    public GameView(Context c){
        super(c);
        setFocusable(true);
        setClickable(true);
        setLayerType(View.LAYER_TYPE_SOFTWARE,null);
        for(int i=0;i<170;i++){
            Obj s=new Obj(rnd.nextInt(1000),rnd.nextInt(1800),.5f+rnd.nextFloat()*2.2f,0);
            s.vy=.35f+rnd.nextFloat()*1.7f;
            stars.add(s);
        }
        playerAtlas=BitmapFactory.decodeResource(getResources(),R.drawable.player_atlas);
        enemyBossAtlas=BitmapFactory.decodeResource(getResources(),R.drawable.enemyboss_atlas);
        menuHd=BitmapFactory.decodeResource(getResources(),R.drawable.galaxy1942_menu_hd);
        last=System.currentTimeMillis();
    }

    private void text(Canvas c,String s,float x,float y,float size,int color,Paint.Align align){
        p.setShader(null); p.setStyle(Paint.Style.FILL); p.setColor(color);
        p.setTextSize(size); p.setTextAlign(align);
        p.setTypeface(Typeface.create("sans",Typeface.BOLD));
        c.drawText(s,x,y,p);
    }
    private void fillRound(Canvas c,float l,float t,float r,float b,float rad,int color){
        p.setShader(null); p.setStyle(Paint.Style.FILL); p.setColor(color);
        c.drawRoundRect(l,t,r,b,rad,rad,p);
    }
    private void strokeRound(Canvas c,float l,float t,float r,float b,float rad,float sw,int color){
        p.setShader(null); p.setStyle(Paint.Style.STROKE); p.setStrokeWidth(sw); p.setColor(color);
        c.drawRoundRect(l,t,r,b,rad,rad,p);
    }
    private float clamp(float v,float a,float b){return Math.max(a,Math.min(b,v));}

    @Override protected void onDraw(Canvas c){
        W=getWidth(); H=getHeight();
        if(W<=0||H<=0)return;
        if(mode==PLAY) drawGame(c);
        else if(mode==CLEAR) drawClear(c);
        else if(mode==DEAD) drawDead(c);
        else drawMenu(c);
    }

    private void drawSpace(Canvas c,boolean gameplay){
        p.setStyle(Paint.Style.FILL);
        p.setShader(new LinearGradient(0,0,0,H,
                gameplay?Color.rgb(2,5,18):Color.rgb(3,5,22),
                gameplay?Color.rgb(10,2,26):Color.rgb(18,3,36),
                Shader.TileMode.CLAMP));
        c.drawRect(0,0,W,H,p); p.setShader(null);

        float nx=W*.18f, ny=H*.24f;
        p.setShader(new RadialGradient(nx,ny,W*.72f,
                Color.argb(95,35,80,210),Color.TRANSPARENT,Shader.TileMode.CLAMP));
        c.drawCircle(nx,ny,W*.72f,p); p.setShader(null);

        float mx=W*.88f, my=H*.12f;
        p.setShader(new RadialGradient(mx,my,W*.58f,
                Color.argb(80,190,35,220),Color.TRANSPARENT,Shader.TileMode.CLAMP));
        c.drawCircle(mx,my,W*.58f,p); p.setShader(null);

        for(Obj s:stars){
            float sx=s.x/1000f*W, sy=s.y/1800f*H;
            int a=100+(int)(s.vy*45);
            p.setColor(Color.argb(Math.min(220,a),150,215,255));
            c.drawCircle(sx,sy,s.r,p);
        }
    }

    private void drawPlanetBackdrop(Canvas c){
        float x=W*.83f, y=H*.18f, r=Math.min(W,H)*.19f;
        p.setStyle(Paint.Style.FILL);
        p.setShader(new RadialGradient(x-r*.32f,y-r*.38f,r*1.22f,
                new int[]{Color.rgb(130,205,255),Color.rgb(55,95,190),Color.rgb(17,20,70)},
                new float[]{0f,.52f,1f},Shader.TileMode.CLAMP));
        c.drawCircle(x,y,r,p); p.setShader(null);

        p.setColor(Color.argb(120,65,225,255));
        c.drawOval(x-r*1.65f,y-r*.26f,x+r*1.65f,y+r*.26f,p);
        p.setColor(Color.argb(190,6,8,28));
        c.drawOval(x-r*1.47f,y-r*.12f,x+r*1.47f,y+r*.12f,p);

        p.setColor(Color.argb(110,13,12,55));
        c.drawCircle(x+r*.24f,y+r*.18f,r*.23f,p);

        Path mountain=new Path();
        mountain.moveTo(0,H*.68f);
        mountain.lineTo(W*.12f,H*.60f);
        mountain.lineTo(W*.24f,H*.67f);
        mountain.lineTo(W*.37f,H*.56f);
        mountain.lineTo(W*.50f,H*.68f);
        mountain.lineTo(W*.67f,H*.57f);
        mountain.lineTo(W*.82f,H*.66f);
        mountain.lineTo(W,H*.58f);
        mountain.lineTo(W,H);
        mountain.lineTo(0,H);
        mountain.close();
        p.setShader(new LinearGradient(0,H*.56f,0,H,
                Color.argb(160,20,30,70),Color.argb(235,4,8,24),Shader.TileMode.CLAMP));
        c.drawPath(mountain,p); p.setShader(null);

        p.setStyle(Paint.Style.STROKE); p.setStrokeWidth(1f); p.setColor(Color.argb(45,60,210,255));
        for(int yGrid=(int)(H*.70f);yGrid<H;yGrid+=34)c.drawLine(0,yGrid,W,yGrid,p);
        for(int xGrid=0;xGrid<W;xGrid+=48)c.drawLine(xGrid,H*.70f,xGrid+(xGrid-W/2)*.18f,H,p);
    }

    private void drawMenu(Canvas c){
        if(menuHd!=null){
            Rect src=new Rect(0,0,menuHd.getWidth(),menuHd.getHeight());
            RectF dst=new RectF(0,0,W,H);
            p.setStyle(Paint.Style.FILL);
            c.drawBitmap(menuHd,src,dst,p);
            // Interactive overlays follow the artwork: ship row and START MISSION.
            float selectTop=H*.22f, selectBottom=H*.46f;
            float gap=W*.012f,left=W*.04f,cw=(W*.92f-gap*4)/5f;
            for(int i=0;i<5;i++){
                float l=left+i*(cw+gap),r=l+cw;
                if(i==ship){
                    p.setStyle(Paint.Style.STROKE); p.setStrokeWidth(3f);
                    p.setColor(Color.argb(235,100,245,255));
                    c.drawRoundRect(l,selectTop,r,selectBottom,16,16,p);
                }
            }
            return;
        }
        drawSpace(c,false);
        drawPlanetBackdrop(c);
        text(c,"GALAXY 1942",W/2,H*.12f,38,Color.WHITE,Paint.Align.CENTER);
        text(c,"HD ART ASSET MISSING",W/2,H*.18f,12,Color.RED,Paint.Align.CENTER);
    }

    private void startStage(){
        mode=PLAY; kills=0; target=10+Math.min(15,stage/2); bossActive=false; bossDying=false; dragging=false;
        enemies.clear(); shots.clear(); enemyShots.clear(); drops.clear(); fx.clear();
        hp=100; power=Math.max(1,power); shield=Math.max(1,shield);
        px=W/2f; py=H*.80f;
        spawnClock=shotClock=enemyShotClock=0;
        last=System.currentTimeMillis();
        invalidate();
    }

    private void drawGame(Canvas c){
        drawSpace(c,true);
        long now=System.currentTimeMillis();
        long elapsed=Math.min(50,Math.max(0,now-last));
        last=now;
        float dt=elapsed/1000f;

        for(Obj s:stars){s.y+=90*s.vy*dt;if(s.y>1800)s.y=0;}
        spawnClock+=elapsed; shotClock+=elapsed; enemyShotClock+=elapsed;

        if(!bossDying && !bossActive && kills<target && spawnClock>430 && enemies.size()<8){
            spawnClock=0; spawnEnemy();
        }
        if(!bossActive && kills>=target && enemies.isEmpty()) spawnBoss();
        if(!bossDying && shotClock>150){shotClock=0;fire();}
        if(!bossDying && enemyShotClock>800){enemyShotClock=0;enemyFire();}

        update(dt);
        for(Fx q:fx)drawFx(c,q);
        for(Obj s:shots)drawPlayerShot(c,s);
        for(Obj s:enemyShots)drawEnemyShot(c,s);
        for(Obj e:enemies)drawEnemy(c,e);
        for(Obj d:drops)drawDrop(c,d);
        drawShip(c,px,py,.95f,ship,true);
        drawHud(c);

        if(bombFlash){
            float a=1f-(System.currentTimeMillis()-bombClock)/420f;
            if(a>0){
                p.setStyle(Paint.Style.FILL); p.setColor(Color.argb((int)(95*a),80,220,255));
                c.drawRect(0,0,W,H,p);
            } else bombFlash=false;
        }
        postInvalidateDelayed(16);
    }

    private void spawnEnemy(){
        int t=rnd.nextInt(6);
        Obj e=new Obj(45+rnd.nextFloat()*(W-90),-70,22+rnd.nextFloat()*9,t);
        e.vy=80+rnd.nextFloat()*75;
        e.hp=1+stage/6; e.maxHp=e.hp;
        e.rot=rnd.nextFloat()*360;
        enemies.add(e);
        burst(e.x,e.y,7,enemyColors[t]);
    }

    private void spawnBoss(){
        bossActive=true;
        Obj e=new Obj(W/2f,-120,82,10);
        e.hp=110+stage*18; e.maxHp=e.hp; e.vy=58;
        enemies.add(e);
        burst(e.x,e.y,55,Color.rgb(235,70,255));
    }

    private void update(float dt){
        for(Obj s:shots){s.y-=920*dt;if(s.y<-60)s.alive=false;}
        for(Obj s:enemyShots){
            s.x+=s.vx*dt; s.y+=s.vy*dt;
            if(s.y>H+50||s.x<-50||s.x>W+50)s.alive=false;
        }
        for(Obj e:enemies){
            e.y+=e.vy*dt;
            if(e.type==10){
                e.x=W/2f+(float)Math.sin(System.currentTimeMillis()*.0015)*W*.29f;
                e.vy=e.y<H*.18f?62:6;
            }else{
                e.x+=(float)Math.sin(e.y*.018f+e.type*1.4f)*55*dt;
                e.rot+=60*dt;
                if(e.y>H+90)e.alive=false;
            }
        }
        for(Obj d:drops){
            d.y+=145*dt; d.rot+=120*dt;
            if(Math.hypot(d.x-px,d.y-py)<58){d.alive=false;collect(d.type);burst(d.x,d.y,18,dropColor(d.type));}
            if(d.y>H+50)d.alive=false;
        }

        for(Obj s:shots)if(s.alive)for(Obj e:enemies)if(e.alive&&Math.hypot(s.x-e.x,s.y-e.y)<e.r+15){
            s.alive=false; e.hp--;
            burst(e.x,e.y,5,e.type==10?Color.rgb(255,95,220):enemyColors[e.type%6]);
            if(e.hp<=0){e.alive=false;kill(e);}
        }

        for(Obj s:enemyShots)if(s.alive&&Math.hypot(s.x-px,s.y-py)<25){
            s.alive=false;
            if(shield>0)shield--; else hp-=8;
            burst(px,py,16,Color.CYAN);
        }

        updateFx(dt);
        clean(shots); clean(enemyShots); clean(enemies); clean(drops);

        if(bossDying){
            long now=System.currentTimeMillis();
            if(now-lastBossBurstClock>115){
                lastBossBurstClock=now;
                float bx=W/2f+(rnd.nextFloat()-.5f)*170;
                float by=H*.20f+(rnd.nextFloat()-.5f)*135;
                burst(bx,by,20,rnd.nextBoolean()?Color.rgb(255,150,35):Color.rgb(255,70,220));
                burst(bx,by,8,Color.WHITE);
            }
            if(now-bossDeathClock>1050){
                bossDying=false; score+=stage*15000; coins+=stage*300; gems+=Math.max(1,stage);
                mode=CLEAR; invalidate(); return;
            }
        }
        if(hp<=0 && mode==PLAY){mode=DEAD;invalidate();}
    }

    private void kill(Obj e){
        if(e.type==10){
            bossDying=true; bossDeathClock=System.currentTimeMillis(); lastBossBurstClock=0;
            bombFlash=true; bombClock=System.currentTimeMillis();
            for(int i=0;i<7;i++){
                float bx=e.x+(rnd.nextFloat()-.5f)*150;
                float by=e.y+(rnd.nextFloat()-.5f)*120;
                burst(bx,by,24,i%2==0?Color.rgb(255,150,35):Color.rgb(255,65,220));
                burst(bx,by,8,Color.WHITE);
            }
            return;
        }
        kills++; score+=140+stage*25; coins+=6+stage;
        burst(e.x,e.y,38,enemyColors[e.type%6]);
        burst(e.x,e.y,14,Color.rgb(255,180,45));
        burst(e.x,e.y,8,Color.WHITE);
        if(rnd.nextFloat()<.92f)drops.add(new Obj(e.x,e.y,19,rnd.nextInt(10)));
    }

    private void collect(int t){
        if(t==0)power=Math.min(5,power+1);
        else if(t==1)shield=Math.min(3,shield+1);
        else if(t==2)hp=Math.min(100,hp+28);
        else if(t==3)bombs=Math.min(5,bombs+1);
        else if(t==4)coins+=120;
        else if(t==5)gems+=4;
        else if(t==6)score+=800;
        else if(t==7)power=5;
        else if(t==8){for(Obj e:enemies)if(e.type!=10)e.hp-=4;}
        else shield=Math.min(3,shield+1);
    }

    private void fire(){
        int n=power>=4?5:power>=2?3:1;
        float spread=14;
        for(int i=0;i<n;i++){
            Obj s=new Obj(px+(i-(n-1)/2f)*spread,py-52,7,ship);
            shots.add(s);
        }
        burst(px,py-48,3,shipColors[ship]);
    }

    private void enemyFire(){
        if(enemies.isEmpty())return;
        Obj t=enemies.get(rnd.nextInt(enemies.size()));
        float dx=px-t.x,dy=py-t.y,len=(float)Math.max(1,Math.hypot(dx,dy));
        int count=t.type==10?5:1;
        for(int i=0;i<count;i++){
            float offset=(i-(count-1)/2f)*.12f;
            float a=(float)Math.atan2(dy,dx)+offset;
            Obj s=new Obj(t.x,t.y+20,8,t.type);
            float sp=t.type==10?190:165;
            s.vx=(float)Math.cos(a)*sp; s.vy=(float)Math.sin(a)*sp;
            enemyShots.add(s);
        }
    }

    private void clean(ArrayList<Obj> a){
        for(int i=a.size()-1;i>=0;i--)if(!a.get(i).alive)a.remove(i);
    }

    private void burst(float x,float y,int n,int color){
        for(int i=0;i<n&&fx.size()<360;i++){
            double a=rnd.nextDouble()*Math.PI*2;
            float sp=35+rnd.nextFloat()*220;
            float life=.25f+rnd.nextFloat()*.70f;
            fx.add(new Fx(x,y,(float)Math.cos(a)*sp,(float)Math.sin(a)*sp,life,2+rnd.nextFloat()*7,color));
        }
    }
    private void updateFx(float dt){
        for(Fx q:fx){q.x+=q.vx*dt;q.y+=q.vy*dt;q.vx*=.965f;q.vy*=.965f;q.life-=dt;}
        for(int i=fx.size()-1;i>=0;i--)if(fx.get(i).life<=0)fx.remove(i);
    }
    private void drawFx(Canvas c,Fx q){
        float a=clamp(q.life/q.maxLife,0,1);
        p.setStyle(Paint.Style.FILL);
        p.setColor(Color.argb((int)(220*a),Color.red(q.color),Color.green(q.color),Color.blue(q.color)));
        c.drawCircle(q.x,q.y,q.size*(.4f+.6f*a),p);
    }

    private void drawPlayerShot(Canvas c,Obj s){
        int col=shipColors[ship];
        p.setStyle(Paint.Style.FILL);
        p.setShader(new RadialGradient(s.x,s.y,18,Color.argb(180,Color.red(col),Color.green(col),Color.blue(col)),Color.TRANSPARENT,Shader.TileMode.CLAMP));
        c.drawCircle(s.x,s.y,18,p); p.setShader(null);
        p.setColor(Color.WHITE); c.drawRoundRect(s.x-3,s.y-24,s.x+3,s.y+17,4,4,p);
        p.setColor(col); c.drawRoundRect(s.x-6,s.y-14,s.x+6,s.y+12,5,5,p);
    }

    private void drawEnemyShot(Canvas c,Obj s){
        int col=s.type==10?Color.rgb(255,65,210):Color.rgb(255,80,120);
        p.setStyle(Paint.Style.FILL);
        p.setShader(new RadialGradient(s.x,s.y,15,Color.argb(200,Color.red(col),Color.green(col),Color.blue(col)),Color.TRANSPARENT,Shader.TileMode.CLAMP));
        c.drawCircle(s.x,s.y,15,p); p.setShader(null);
        p.setColor(Color.WHITE); c.drawCircle(s.x,s.y,4,p);
    }

    private boolean drawPlayerSprite(Canvas c,float x,float y,float sc,int v,boolean glow){
        if(playerAtlas==null||playerAtlas.isRecycled())return false;
        int idx=Math.floorMod(v,5);
        int[] a=PLAYER_SRC[idx];
        Rect src=new Rect(a[0],a[1],a[2],a[3]);
        float ratio=(a[2]-a[0])/(float)Math.max(1,a[3]-a[1]);
        float h=142f*sc;
        float w=h*ratio;
        if(glow){
            int col=shipColors[idx];
            p.setStyle(Paint.Style.FILL);
            p.setShader(new RadialGradient(x,y+8*sc,82*sc,Color.argb(120,Color.red(col),Color.green(col),Color.blue(col)),Color.TRANSPARENT,Shader.TileMode.CLAMP));
            c.drawCircle(x,y+8*sc,82*sc,p); p.setShader(null);
        }
        p.setAlpha(255);
        p.setFilterBitmap(true);
        c.drawBitmap(playerAtlas,src,new RectF(x-w/2,y-h/2,x+w/2,y+h/2),p);
        return true;
    }

    private boolean drawEnemySprite(Canvas c,Obj e){
        if(enemyBossAtlas==null||enemyBossAtlas.isRecycled())return false;
        Rect src;
        if(e.type==10){
            int bossIdx=Math.floorMod(stage-1,3);
            int[] a=BOSS_SRC[bossIdx];
            src=new Rect(a[0],a[1],a[2],a[3]);
            float h=e.r*2.9f,w=h*((a[2]-a[0])/(float)(a[3]-a[1]));
            p.setStyle(Paint.Style.FILL);
            p.setShader(new RadialGradient(e.x,e.y,e.r*1.95f,Color.argb(165,235,55,255),Color.TRANSPARENT,Shader.TileMode.CLAMP));
            c.drawCircle(e.x,e.y,e.r*1.95f,p);p.setShader(null);
            p.setAlpha(255); p.setFilterBitmap(true);
            c.drawBitmap(enemyBossAtlas,src,new RectF(e.x-w/2,e.y-h/2,e.x+w/2,e.y+h/2),p);
            return true;
        }
        int idx=Math.floorMod(e.type,6);
        int[] a=ENEMY_SRC[idx];
        src=new Rect(a[0],a[1],a[2],a[3]);
        float h=e.r*3.2f,w=h*((a[2]-a[0])/(float)(a[3]-a[1]));
        p.setAlpha(255); p.setFilterBitmap(true);
        c.drawBitmap(enemyBossAtlas,src,new RectF(e.x-w/2,e.y-h/2,e.x+w/2,e.y+h/2),p);
        return true;
    }

    private void drawShip(Canvas c,float x,float y,float sc,int v,boolean glow){
        if(drawPlayerSprite(c,x,y,sc,v,glow))return;
        int col=shipColors[Math.floorMod(v,5)];
        if(glow){
            p.setStyle(Paint.Style.FILL);
            p.setShader(new RadialGradient(x,y+8*sc,78*sc,Color.argb(135,Color.red(col),Color.green(col),Color.blue(col)),Color.TRANSPARENT,Shader.TileMode.CLAMP));
            c.drawCircle(x,y+8*sc,78*sc,p); p.setShader(null);
        }

        Path wing=new Path();
        if(v==0){
            wing.moveTo(x,y-58*sc); wing.lineTo(x-18*sc,y-18*sc); wing.lineTo(x-62*sc,y+22*sc);
            wing.lineTo(x-31*sc,y+18*sc); wing.lineTo(x-36*sc,y+45*sc); wing.lineTo(x,y+28*sc);
            wing.lineTo(x+36*sc,y+45*sc); wing.lineTo(x+31*sc,y+18*sc); wing.lineTo(x+62*sc,y+22*sc); wing.lineTo(x+18*sc,y-18*sc);
        }else if(v==1){
            wing.moveTo(x,y-62*sc); wing.lineTo(x-13*sc,y-20*sc); wing.lineTo(x-55*sc,y+8*sc);
            wing.lineTo(x-20*sc,y+17*sc); wing.lineTo(x-25*sc,y+48*sc); wing.lineTo(x,y+29*sc);
            wing.lineTo(x+25*sc,y+48*sc); wing.lineTo(x+20*sc,y+17*sc); wing.lineTo(x+55*sc,y+8*sc); wing.lineTo(x+13*sc,y-20*sc);
        }else if(v==2){
            wing.moveTo(x,y-55*sc); wing.lineTo(x-22*sc,y-13*sc); wing.lineTo(x-67*sc,y+30*sc);
            wing.lineTo(x-29*sc,y+24*sc); wing.lineTo(x-14*sc,y+49*sc); wing.lineTo(x,y+31*sc);
            wing.lineTo(x+14*sc,y+49*sc); wing.lineTo(x+29*sc,y+24*sc); wing.lineTo(x+67*sc,y+30*sc); wing.lineTo(x+22*sc,y-13*sc);
        }else if(v==3){
            wing.moveTo(x,y-60*sc); wing.lineTo(x-24*sc,y-22*sc); wing.lineTo(x-57*sc,y+28*sc);
            wing.lineTo(x-37*sc,y+37*sc); wing.lineTo(x-10*sc,y+45*sc); wing.lineTo(x,y+31*sc);
            wing.lineTo(x+10*sc,y+45*sc); wing.lineTo(x+37*sc,y+37*sc); wing.lineTo(x+57*sc,y+28*sc); wing.lineTo(x+24*sc,y-22*sc);
        }else{
            wing.moveTo(x,y-66*sc); wing.lineTo(x-16*sc,y-24*sc); wing.lineTo(x-48*sc,y-5*sc);
            wing.lineTo(x-63*sc,y+28*sc); wing.lineTo(x-24*sc,y+17*sc); wing.lineTo(x-16*sc,y+48*sc);
            wing.lineTo(x,y+31*sc); wing.lineTo(x+16*sc,y+48*sc); wing.lineTo(x+24*sc,y+17*sc);
            wing.lineTo(x+63*sc,y+28*sc); wing.lineTo(x+48*sc,y-5*sc); wing.lineTo(x+16*sc,y-24*sc);
        }
        wing.close();

        p.setStyle(Paint.Style.FILL);
        p.setShader(new LinearGradient(x,y-65*sc,x,y+50*sc,Color.WHITE,col,Shader.TileMode.CLAMP));
        c.drawPath(wing,p); p.setShader(null);

        p.setStyle(Paint.Style.STROKE); p.setStrokeWidth(1.4f*sc); p.setColor(Color.argb(210,255,255,255));
        c.drawPath(wing,p);

        p.setStyle(Paint.Style.FILL);
        Path body=new Path();
        body.moveTo(x,y-58*sc); body.cubicTo(x+15*sc,y-33*sc,x+15*sc,y+19*sc,x,y+43*sc);
        body.cubicTo(x-15*sc,y+19*sc,x-15*sc,y-33*sc,x,y-58*sc); body.close();
        p.setColor(Color.rgb(225,235,245)); c.drawPath(body,p);

        p.setColor(Color.rgb(18,35,65));
        Path canopy=new Path();
        canopy.moveTo(x,y-35*sc); canopy.lineTo(x-8*sc,y-7*sc); canopy.lineTo(x+8*sc,y-7*sc); canopy.close();
        c.drawPath(canopy,p);
        p.setColor(Color.WHITE); c.drawCircle(x,y-18*sc,3*sc,p);

        p.setShader(new LinearGradient(x,y+25*sc,x,y+66*sc,col,Color.TRANSPARENT,Shader.TileMode.CLAMP));
        c.drawOval(x-7*sc,y+24*sc,x+7*sc,y+66*sc,p); p.setShader(null);
    }

    private void drawEnemy(Canvas c,Obj e){
        if(drawEnemySprite(c,e))return;
        if(e.type==10){drawBoss(c,e);return;}
        int col=enemyColors[e.type%6];
        p.setStyle(Paint.Style.FILL);
        p.setShader(new RadialGradient(e.x,e.y,44,Color.argb(150,Color.red(col),Color.green(col),Color.blue(col)),Color.TRANSPARENT,Shader.TileMode.CLAMP));
        c.drawCircle(e.x,e.y,44,p); p.setShader(null);

        c.save(); c.rotate(e.type%2==0?0:(float)Math.sin(e.y*.02f)*12,e.x,e.y);
        Path q=new Path();
        if(e.type%3==0){
            q.moveTo(e.x,e.y-30); q.lineTo(e.x-34,e.y+9); q.lineTo(e.x-15,e.y+30);
            q.lineTo(e.x,e.y+18); q.lineTo(e.x+15,e.y+30); q.lineTo(e.x+34,e.y+9);
        }else if(e.type%3==1){
            q.moveTo(e.x,e.y-26); q.lineTo(e.x-42,e.y-4); q.lineTo(e.x-22,e.y+26);
            q.lineTo(e.x,e.y+16); q.lineTo(e.x+22,e.y+26); q.lineTo(e.x+42,e.y-4);
        }else{
            q.moveTo(e.x,e.y-34); q.lineTo(e.x-26,e.y-6); q.lineTo(e.x-39,e.y+22);
            q.lineTo(e.x,e.y+11); q.lineTo(e.x+39,e.y+22); q.lineTo(e.x+26,e.y-6);
        }
        q.close();
        p.setShader(new LinearGradient(e.x,e.y-35,e.x,e.y+35,Color.WHITE,col,Shader.TileMode.CLAMP));
        c.drawPath(q,p); p.setShader(null);
        p.setColor(Color.rgb(18,23,45)); c.drawOval(e.x-10,e.y-12,e.x+10,e.y+9,p);
        p.setColor(Color.WHITE); c.drawCircle(e.x,e.y-4,3,p);
        c.restore();
    }

    private void drawBoss(Canvas c,Obj e){
        int col=Color.rgb(230,65,255);
        p.setStyle(Paint.Style.FILL);
        p.setShader(new RadialGradient(e.x,e.y,135,Color.argb(165,220,45,255),Color.TRANSPARENT,Shader.TileMode.CLAMP));
        c.drawCircle(e.x,e.y,135,p); p.setShader(null);

        Path hull=new Path();
        hull.moveTo(e.x,e.y-82);
        hull.lineTo(e.x-40,e.y-48);
        hull.lineTo(e.x-92,e.y-26);
        hull.lineTo(e.x-73,e.y+42);
        hull.lineTo(e.x-34,e.y+68);
        hull.lineTo(e.x,e.y+46);
        hull.lineTo(e.x+34,e.y+68);
        hull.lineTo(e.x+73,e.y+42);
        hull.lineTo(e.x+92,e.y-26);
        hull.lineTo(e.x+40,e.y-48);
        hull.close();
        p.setColor(Color.rgb(34,18,68)); c.drawPath(hull,p);
        p.setStyle(Paint.Style.STROKE); p.setStrokeWidth(6); p.setColor(col); c.drawPath(hull,p);

        p.setStyle(Paint.Style.FILL);
        p.setShader(new RadialGradient(e.x,e.y,34,Color.WHITE,Color.rgb(255,55,210),Shader.TileMode.CLAMP));
        c.drawCircle(e.x,e.y,30,p); p.setShader(null);
        p.setColor(Color.rgb(15,10,42)); c.drawCircle(e.x,e.y,10,p);

        for(int side=-1;side<=1;side+=2){
            p.setColor(Color.rgb(255,185,60));
            c.drawCircle(e.x+side*48,e.y+25,7,p);
            p.setShader(new LinearGradient(e.x+side*48,e.y+31,e.x+side*48,e.y+75,Color.rgb(255,110,55),Color.TRANSPARENT,Shader.TileMode.CLAMP));
            c.drawOval(e.x+side*54,e.y+28,e.x+side*42,e.y+78,p); p.setShader(null);
        }
    }

    private int dropColor(int t){
        if(t==0)return Color.rgb(70,235,255);
        if(t==1)return Color.rgb(75,180,255);
        if(t==2)return Color.rgb(65,235,120);
        if(t==3)return Color.rgb(255,190,55);
        if(t==4)return Color.YELLOW;
        if(t==5)return Color.MAGENTA;
        if(t==7)return Color.rgb(255,90,220);
        return Color.rgb(155,225,255);
    }

    private void drawDrop(Canvas c,Obj d){
        int col=dropColor(d.type);
        p.setStyle(Paint.Style.FILL);
        p.setShader(new RadialGradient(d.x,d.y,34,Color.argb(150,Color.red(col),Color.green(col),Color.blue(col)),Color.TRANSPARENT,Shader.TileMode.CLAMP));
        c.drawCircle(d.x,d.y,34,p); p.setShader(null);

        c.save(); c.rotate(d.rot,d.x,d.y);
        Path gem=new Path();
        gem.moveTo(d.x,d.y-15); gem.lineTo(d.x-13,d.y); gem.lineTo(d.x,d.y+15); gem.lineTo(d.x+13,d.y); gem.close();
        p.setColor(col); c.drawPath(gem,p);
        p.setStyle(Paint.Style.STROKE); p.setStrokeWidth(2); p.setColor(Color.WHITE); c.drawPath(gem,p);
        c.restore();

        String label=d.type==0?"P":d.type==1?"S":d.type==2?"+":d.type==3?"B":d.type==4?"C":d.type==5?"G":d.type==7?"MAX":"✦";
        text(c,label,d.x,d.y+4,9,Color.WHITE,Paint.Align.CENTER);
    }

    private void drawHud(Canvas c){
        fillRound(c,8,8,W-8,62,17,Color.argb(205,3,10,25));
        strokeRound(c,8,8,W-8,62,17,1,Color.argb(100,80,210,255));
        text(c,"STAGE "+stage,18,29,12,Color.WHITE,Paint.Align.LEFT);
        text(c,"SCORE "+score,W/2,29,12,Color.WHITE,Paint.Align.CENTER);
        text(c,"BOMB "+bombs,W-18,29,11,Color.YELLOW,Paint.Align.RIGHT);

        text(c,"HP",18,50,9,Color.WHITE,Paint.Align.LEFT);
        fillRound(c,42,41,142,52,5,Color.rgb(35,40,55));
        fillRound(c,42,41,42+100*hp/100f,52,5,Color.rgb(45,225,125));
        text(c,"PWR "+power,154,50,9,Color.CYAN,Paint.Align.LEFT);

        if(bossActive&&!enemies.isEmpty()){
            Obj b=enemies.get(0);
            text(c,"VOID EMPEROR",W/2,83,11,Color.rgb(255,105,225),Paint.Align.CENTER);
            fillRound(c,32,91,W-32,103,6,Color.rgb(35,25,45));
            float ratio=Math.max(0,b.hp)/(float)Math.max(1,b.maxHp);
            fillRound(c,32,91,32+(W-64)*ratio,103,6,Color.rgb(230,55,210));
        }

        fillRound(c,14,H-86,112,H-20,20,Color.argb(200,4,20,42));
        strokeRound(c,14,H-86,112,H-20,20,2,Color.rgb(55,180,220));
        text(c,"NOVA BOMB",63,H-51,10,Color.YELLOW,Paint.Align.CENTER);
        text(c,"TAP",63,H-31,8,Color.LTGRAY,Paint.Align.CENTER);
    }

    private void drawClear(Canvas c){
        drawSpace(c,false);
        drawPlanetBackdrop(c);
        text(c,"STAGE CLEAR",W/2,H*.22f,36,Color.WHITE,Paint.Align.CENTER);
        text(c,"VOID EMPEROR DESTROYED",W/2,H*.27f,12,Color.rgb(255,110,220),Paint.Align.CENTER);
        text(c,"SCORE "+score,W/2,H*.34f,17,Color.YELLOW,Paint.Align.CENTER);
        text(c,"+"+(stage*300)+" COINS   +"+Math.max(1,stage)+" GEMS",W/2,H*.39f,12,Color.CYAN,Paint.Align.CENTER);

        fillRound(c,W*.08f,H*.48f,W*.92f,H*.58f,20,Color.rgb(8,115,160));
        strokeRound(c,W*.08f,H*.48f,W*.92f,H*.58f,20,2,Color.CYAN);
        text(c,"WATCH AD  •  NEXT STAGE",W/2,H*.54f,15,Color.WHITE,Paint.Align.CENTER);

        fillRound(c,W*.15f,H*.62f,W*.85f,H*.70f,18,Color.rgb(20,40,65));
        text(c,"CONTINUE WITHOUT AD",W/2,H*.67f,12,Color.LTGRAY,Paint.Align.CENTER);
        text(c,"Ads never interrupt active combat.",W/2,H*.78f,10,Color.rgb(110,185,215),Paint.Align.CENTER);
    }

    private void drawDead(Canvas c){
        drawSpace(c,false);
        text(c,"MISSION FAILED",W/2,H*.30f,34,Color.WHITE,Paint.Align.CENTER);
        text(c,"SCORE "+score,W/2,H*.36f,16,Color.YELLOW,Paint.Align.CENTER);
        fillRound(c,W*.12f,H*.46f,W*.88f,H*.56f,20,Color.rgb(125,35,70));
        text(c,"RETRY STAGE",W/2,H*.52f,16,Color.WHITE,Paint.Align.CENTER);
    }

    @Override public boolean onTouchEvent(MotionEvent e){
        float x=e.getX(),y=e.getY();
        int action=e.getActionMasked();

        if(action==MotionEvent.ACTION_DOWN){
            performClick();

            if(mode==MENU){
                // HD menu artwork: fighters occupy the middle ship row.
                if(y>=H*.22f&&y<=H*.47f){
                    float gap=W*.012f,left=W*.04f,cw=(W*.92f-gap*4)/5f;
                    int pick=(int)((x-left)/(cw+gap));
                    if(pick>=0&&pick<5){
                        float l=left+pick*(cw+gap);
                        if(x>=l&&x<=l+cw){ship=pick;invalidate();return true;}
                    }
                }
                // Large orange START MISSION button in the generated artwork.
                if(y>=H*.44f&&y<=H*.56f){startStage();return true;}
                return true;
            }

            if(mode==PLAY){
                if(y>H-125&&x<140){
                    if(bombs>0){
                        bombs--; bombFlash=true; bombClock=System.currentTimeMillis();
                        for(Obj en:enemies){
                            if(en.type!=10){
                                en.hp-=5;
                                if(en.hp<=0){en.alive=false;kill(en);}
                            }
                        }
                        burst(px,py,45,Color.CYAN);
                    }
                    return true;
                }
                dragging=true;
                touchAnchorX=x; touchAnchorY=y;
                shipAnchorX=px; shipAnchorY=py;
                return true;
            }

            if(mode==DEAD){
                if(y>=H*.42f&&y<=H*.60f){startStage();return true;}
                return true;
            }

            if(mode==CLEAR){
                if(y>=H*.45f&&y<=H*.60f){
                    try{
                        Intent i=new Intent(Intent.ACTION_VIEW,Uri.parse(MONETAG_URL));
                        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                        getContext().startActivity(i);
                    }catch(Exception ignored){}
                    stage++; mode=MENU; invalidate(); return true;
                }
                if(y>=H*.60f&&y<=H*.73f){
                    stage++; mode=MENU; invalidate(); return true;
                }
                return true;
            }
        }

        if(action==MotionEvent.ACTION_MOVE&&mode==PLAY&&dragging){
            float dx=x-touchAnchorX,dy=y-touchAnchorY;
            px=clamp(shipAnchorX+dx,32,W-32);
            py=clamp(shipAnchorY+dy,100,H-150);
            return true;
        }
        if(action==MotionEvent.ACTION_UP&&mode==PLAY){
            if(dragging){
                float dx=x-touchAnchorX,dy=y-touchAnchorY;
                px=clamp(shipAnchorX+dx,32,W-32);
                py=clamp(shipAnchorY+dy,100,H-150);
            }
            dragging=false;
            return true;
        }
        return true;
    }

    @Override public boolean performClick(){
        super.performClick();
        return true;
    }
}
