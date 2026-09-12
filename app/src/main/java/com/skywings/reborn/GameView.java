package com.skywings.reborn;

import android.app.AlertDialog;
import android.content.Context;
import android.graphics.*;
import android.view.MotionEvent;
import android.view.View;
import android.widget.EditText;
import java.util.ArrayList;
import java.util.Random;

public class GameView extends View {
    private static final int ORIGIN=0, BASE=1, LANDING=2, ASSAULT=3;
    private static final float WORLD_W=3200f, WORLD_H=2200f;

    private final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Random rnd=new Random(1942);
    private Bitmap strategyArt, playerAtlas;

    private int mode=ORIGIN, selectedPlanet=0, landingZone=0;
    private String planetName="MyPlanet";
    private int credits=5000, metal=2500, crystal=800, oil=3000;
    private int baseLevel=1, wingmen=0;

    private float playerX=260, playerY=1100, camX=0, camY=0;
    private float cameraYaw=0f, cameraPitch=.78f, cameraZoom=.88f;
    private float camTouchX,camTouchY;
    private int joystickPointer=-1, cameraPointer=-1, firePointer=-1;
    private float joyX=0f, joyY=0f;
    private boolean fireHeld=false;
    private long lastShot=0L;
    private final ArrayList<Bullet> bullets=new ArrayList<>();

    private final String[] names={"OCEAN WORLD","DESERT WORLD","ICE WORLD","FOREST WORLD"};
    private final ArrayList<Site> sites=new ArrayList<>();
    private final ArrayList<PointF> explored=new ArrayList<>();

    private static class Site {
        float x,y,r; int type,hp; boolean destroyed=false, discovered=false;
        Site(float x,float y,float r,int type,int hp){this.x=x;this.y=y;this.r=r;this.type=type;this.hp=hp;}
    }
    private static class Bullet {
        float x,y,vx,vy; int life=120;
        Bullet(float x,float y,float vx,float vy){this.x=x;this.y=y;this.vx=vx;this.vy=vy;}
    }

    public GameView(Context c){
        super(c);
        setFocusable(true); setClickable(true);
        strategyArt=BitmapFactory.decodeResource(getResources(),R.drawable.galaxy1942_strategy_art);
        playerAtlas=BitmapFactory.decodeResource(getResources(),R.drawable.player_atlas);
        buildWorld();
    }

    private void buildWorld(){
        sites.clear();
        // 0 radar,1 oil,2 metal,3 crystal,4 AA,5 SAM,6 drone,7 factory,8 HQ
        sites.add(new Site(520,420,60,0,90));
        sites.add(new Site(820,1680,70,1,100));
        sites.add(new Site(1320,520,70,2,100));
        sites.add(new Site(1880,1780,70,3,110));
        sites.add(new Site(1480,1080,58,4,120));
        sites.add(new Site(2220,700,58,5,130));
        sites.add(new Site(2500,1450,64,6,120));
        sites.add(new Site(2720,520,85,7,180));
        sites.add(new Site(2850,1100,120,8,350));
        for(int i=0;i<8;i++){
            sites.add(new Site(700+rnd.nextInt(2100),300+rnd.nextInt(1500),42,4+rnd.nextInt(3),80+rnd.nextInt(70)));
        }
    }

    private void txt(Canvas c,String s,float x,float y,float z,int color,Paint.Align a){
        p.setShader(null);p.setStyle(Paint.Style.FILL);p.setColor(color);p.setTextAlign(a);
        p.setTypeface(Typeface.create("sans",Typeface.BOLD));p.setTextSize(z);c.drawText(s,x,y,p);
    }
    private void box(Canvas c,float l,float t,float r,float b,float rad,int color){
        p.setShader(null);p.setStyle(Paint.Style.FILL);p.setColor(color);c.drawRoundRect(l,t,r,b,rad,rad,p);
    }
    private void stroke(Canvas c,float l,float t,float r,float b,float rad,float sw,int color){
        p.setShader(null);p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(sw);p.setColor(color);c.drawRoundRect(l,t,r,b,rad,rad,p);
    }
    private float clamp(float v,float a,float b){return Math.max(a,Math.min(b,v));}

    private void drawArtPanel(Canvas c,int panel){
        int W=getWidth(),H=getHeight();
        if(strategyArt==null || strategyArt.isRecycled()){c.drawColor(0xff030814);return;}
        int sw=strategyArt.getWidth()/2, sh=strategyArt.getHeight()/2;
        int sx=(panel%2)*sw, sy=(panel/2)*sh;
        Rect src=new Rect(sx,sy,sx+sw,sy+sh);
        p.setAlpha(255);p.setFilterBitmap(true);p.setStyle(Paint.Style.FILL);
        c.drawBitmap(strategyArt,src,new RectF(0,0,W,H),p);
    }

    @Override protected void onDraw(Canvas c){
        if(mode==ORIGIN)drawOrigin(c);
        else if(mode==BASE)drawBase(c);
        else if(mode==LANDING)drawLanding(c);
        else drawAssault(c);
    }

    private void drawOrigin(Canvas c){
        int W=getWidth(),H=getHeight();
        drawArtPanel(c,0);
        box(c,0,H*.78f,W,H,0,0x99020814);
        float gap=W*.015f,left=W*.025f,cw=(W*.95f-gap*3)/4f;
        for(int i=0;i<4;i++){
            float l=left+i*(cw+gap),r=l+cw;
            if(i==selectedPlanet)stroke(c,l,H*.16f,r,H*.72f,18,5,0xff69eaff);
        }
        box(c,W*.29f,H*.80f,W*.71f,H*.87f,16,0xdd071a31);
        stroke(c,W*.29f,H*.80f,W*.71f,H*.87f,16,2,0xff55cfff);
        txt(c,"PLANET NAME: "+planetName,W*.5f,H*.845f,18,Color.WHITE,Paint.Align.CENTER);
        box(c,W*.31f,H*.89f,W*.69f,H*.975f,20,0xffff6a00);
        txt(c,"START GAME",W*.5f,H*.946f,28,Color.WHITE,Paint.Align.CENTER);
    }

    private void drawBase(Canvas c){
        int W=getWidth(),H=getHeight();
        drawArtPanel(c,1);
        box(c,0,0,W,H,0,0x22020814);
        box(c,15,12,W-15,70,14,0xbb03101f);
        txt(c,planetName+"  •  HOME PLANET",28,48,27,Color.WHITE,Paint.Align.LEFT);
        txt(c,"Credits "+credits+"   Metal "+metal+"   Crystal "+crystal+"   Oil "+oil,W-28,44,16,0xffffd45a,Paint.Align.RIGHT);
        txt(c,"Base Lv."+baseLevel+"   Wingmen "+wingmen+"/3",26,H-27,17,Color.WHITE,Paint.Align.LEFT);
        menuButton(c,W*.56f,H*.82f,W*.75f,H*.94f,"UPGRADE",0xff1b7e9f);
        menuButton(c,W*.77f,H*.82f,W*.97f,H*.94f,"INVADE PLANET",0xffb6531c);
    }

    private void drawLanding(Canvas c){
        int W=getWidth(),H=getHeight();
        c.drawColor(0xff020815);
        // stylized planet tactical scan; only landing zones are known, enemy locations hidden
        float cx=W*.5f,cy=H*.48f,rr=Math.min(W,H)*.36f;
        p.setShader(new RadialGradient(cx-rr*.25f,cy-rr*.25f,rr,
                new int[]{0xff6cb9d9,0xff2e6d59,0xff17304b,0xff06101e},
                new float[]{0f,.35f,.72f,1f},Shader.TileMode.CLAMP));
        c.drawCircle(cx,cy,rr,p);p.setShader(null);
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(2);p.setColor(0x8845dfff);
        for(int i=1;i<=3;i++)c.drawCircle(cx,cy,rr*i/3f,p);
        txt(c,"SELECT LANDING ZONE",W/2,52,30,Color.WHITE,Paint.Align.CENTER);
        txt(c,"Enemy bases and resources are hidden until you scout them",W/2,80,15,0xff8ddfff,Paint.Align.CENTER);
        float[][] z={{cx,cy-rr*.78f},{cx+rr*.78f,cy},{cx,cy+rr*.78f},{cx-rr*.78f,cy}};
        String[] zn={"NORTH","EAST","SOUTH","WEST"};
        for(int i=0;i<4;i++){
            float x=z[i][0],y=z[i][1];
            p.setStyle(Paint.Style.FILL);p.setColor(i==landingZone?0xffff8a00:0xff1b8dcc);c.drawCircle(x,y,28,p);
            stroke(c,x-36,y-36,x+36,y+36,18,3,Color.WHITE);
            txt(c,zn[i],x,y+58,13,Color.WHITE,Paint.Align.CENTER);
        }
        menuButton(c,W*.37f,H*.84f,W*.63f,H*.95f,"DEPLOY FLEET",0xffff6a00);
        menuButton(c,18,H*.86f,150,H*.95f,"BACK",0xff3b5266);
    }

    private void startAssault(){
        mode=ASSAULT;
        if(landingZone==0){playerX=WORLD_W*.50f;playerY=120;}
        else if(landingZone==1){playerX=WORLD_W-120;playerY=WORLD_H*.50f;}
        else if(landingZone==2){playerX=WORLD_W*.50f;playerY=WORLD_H-120;}
        else {playerX=120;playerY=WORLD_H*.50f;}
        camX=playerX-getWidth()/2f;camY=playerY-getHeight()/2f;
        explored.clear(); explored.add(new PointF(playerX,playerY));
        joystickPointer=cameraPointer=firePointer=-1;
        joyX=joyY=0f; fireHeld=false; bullets.clear();
        cameraYaw=0f; cameraPitch=.78f; cameraZoom=.88f;
        invalidate();
    }

    private void drawAssault(Canvas c){
        updateGameplay();
        updateCamera();
        int W=getWidth(),H=getHeight();
        c.save();
        float cx=W/2f, cy=H/2f;
        c.rotate(cameraYaw,cx,cy);
        c.scale(cameraZoom,cameraZoom*cameraPitch,cx,cy);
        drawWorld(c);
        drawSites(c);
        drawBullets(c);
        drawWingmen(c);
        drawPlayer(c);
        drawFog(c);
        c.restore();
        drawHud(c);
        drawControls(c);
        postInvalidateDelayed(16);
    }

    private void updateGameplay(){
        float speed=9.0f;
        if(Math.abs(joyX)>.02f||Math.abs(joyY)>.02f){
            // Joystick movement is relative to the current camera angle, like an MMO.
            double a=Math.toRadians(cameraYaw);
            float wx=(float)(joyX*Math.cos(a)-joyY*Math.sin(a));
            float wy=(float)(joyX*Math.sin(a)+joyY*Math.cos(a));
            playerX=clamp(playerX+wx*speed,40,WORLD_W-40);
            playerY=clamp(playerY+wy*speed,40,WORLD_H-40);
            if(explored.isEmpty()||Math.hypot(playerX-explored.get(explored.size()-1).x,playerY-explored.get(explored.size()-1).y)>180)
                explored.add(new PointF(playerX,playerY));
        }
        if(fireHeld && System.currentTimeMillis()-lastShot>145) fireWeapon();
        for(int i=bullets.size()-1;i>=0;i--){
            Bullet b=bullets.get(i); b.x+=b.vx; b.y+=b.vy; b.life--;
            for(Site s:sites){
                if(!s.destroyed && s.discovered && Math.hypot(b.x-s.x,b.y-s.y)<s.r+18){
                    s.hp-=24; b.life=0;
                    if(s.hp<=0){
                        s.destroyed=true;
                        if(s.type==1)oil+=250; else if(s.type==2)metal+=220; else if(s.type==3)crystal+=80; else credits+=120;
                    }
                    break;
                }
            }
            if(b.life<=0||b.x<0||b.y<0||b.x>WORLD_W||b.y>WORLD_H) bullets.remove(i);
        }
    }

    private void fireWeapon(){
        lastShot=System.currentTimeMillis();
        // Fire toward the top of the current camera view.
        double a=Math.toRadians(cameraYaw-90f);
        float sp=24f;
        bullets.add(new Bullet(playerX,playerY,(float)Math.cos(a)*sp,(float)Math.sin(a)*sp));
    }

    private void drawBullets(Canvas c){
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(6);p.setColor(0xffffc144);
        for(Bullet b:bullets){
            float x=b.x-camX,y=b.y-camY;
            c.drawLine(x,y,x-b.vx*.65f,y-b.vy*.65f,p);
        }
    }

    private void updateCamera(){
        float targetX=playerX-getWidth()/2f, targetY=playerY-getHeight()/2f;
        camX += (targetX-camX)*.12f;
        camY += (targetY-camY)*.12f;
        camX=clamp(camX,0,Math.max(0,WORLD_W-getWidth()));
        camY=clamp(camY,0,Math.max(0,WORLD_H-getHeight()));
    }

    private void drawWorld(Canvas c){
        int W=getWidth(),H=getHeight();
        c.drawColor(0xff18331f);
        // large RTS-style terrain: land, roads, water, forest, cliffs
        p.setStyle(Paint.Style.FILL);
        p.setColor(0xff315b32);c.drawRect(0,0,W,H,p);
        // world-space water translated by camera
        drawWorldRect(c,-camX,-camY+1500,WORLD_W-camX,WORLD_H-camY,0xff235d78);
        drawWorldRect(c,260-camX,700-camY,2940-camX,830-camY,0xff4b4b46);
        drawWorldRect(c,900-camX,80-camY,1030-camX,1900-camY,0xff494944);
        // vegetation patches
        p.setColor(0xff214a29);
        for(int i=0;i<45;i++){
            float x=(i*397%3100)-camX,y=(i*613%1450)-camY;
            c.drawCircle(x,y,36+(i%4)*10,p);
        }
        // coastline detail
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(10);p.setColor(0xff62a5a7);
        c.drawLine(-camX,1500-camY,WORLD_W-camX,1500-camY,p);
    }

    private void drawWorldRect(Canvas c,float l,float t,float r,float b,int col){
        p.setStyle(Paint.Style.FILL);p.setColor(col);c.drawRect(l,t,r,b,p);
    }

    private void drawSites(Canvas c){
        float reveal=520f;
        for(Site s:sites){
            float d=(float)Math.hypot(s.x-playerX,s.y-playerY);
            if(d<reveal)s.discovered=true;
            if(!s.discovered||s.destroyed)continue;
            float x=s.x-camX,y=s.y-camY;
            if(x<-100||y<-100||x>getWidth()+100||y>getHeight()+100)continue;
            int col=s.type==8?0xffff3c32:(s.type>=4?0xffff684f:0xffffc64e);
            p.setStyle(Paint.Style.FILL);p.setColor(0xdd121820);c.drawCircle(x,y,s.r,p);
            p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(4);p.setColor(col);c.drawCircle(x,y,s.r,p);
            String label;
            if(s.type==0)label="RADAR";else if(s.type==1)label="OIL";
            else if(s.type==2)label="METAL";else if(s.type==3)label="CRYSTAL";
            else if(s.type==4)label="AA";else if(s.type==5)label="SAM";
            else if(s.type==6)label="DRONE";else if(s.type==7)label="FACTORY";else label="COMMAND";
            txt(c,label,x,y+5,12,Color.WHITE,Paint.Align.CENTER);
        }
    }

    private void drawPlayer(Canvas c){
        float x=playerX-camX,y=playerY-camY;
        if(playerAtlas!=null&&!playerAtlas.isRecycled()){
            int sw=Math.max(1,playerAtlas.getWidth()/5);
            int idx=2;
            Rect src=new Rect(idx*sw,0,Math.min(playerAtlas.getWidth(),(idx+1)*sw),playerAtlas.getHeight());
            RectF dst=new RectF(x-52,y-42,x+52,y+42);
            p.setFilterBitmap(true);p.setAlpha(255);c.drawBitmap(playerAtlas,src,dst,p);
        }else{
            p.setStyle(Paint.Style.FILL);p.setColor(0xff55ddff);c.drawCircle(x,y,28,p);
        }
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(2);p.setColor(0x8855eaff);c.drawCircle(x,y,64,p);
    }

    private void drawWingmen(Canvas c){
        for(int i=0;i<wingmen;i++){
            float ang=(float)(Math.PI*(.75+i*.25));
            float wx=playerX+(float)Math.cos(ang)*95-camX;
            float wy=playerY+(float)Math.sin(ang)*95-camY;
            p.setStyle(Paint.Style.FILL);p.setColor(0xff9df4ff);c.drawCircle(wx,wy,14,p);
            p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(2);p.setColor(0xff46cfff);c.drawCircle(wx,wy,24,p);
        }
    }

    private void drawFog(Canvas c){
        // MMO exploration fog: darken outside visual radius, keep previously explored area faintly visible
        float sx=playerX-camX,sy=playerY-camY;
        p.setStyle(Paint.Style.FILL);p.setColor(0xaa00040c);
        Path fog=new Path();fog.setFillType(Path.FillType.EVEN_ODD);
        fog.addRect(0,0,getWidth(),getHeight(),Path.Direction.CW);
        fog.addCircle(sx,sy,360,Path.Direction.CCW);
        c.drawPath(fog,p);
        p.setShader(new RadialGradient(sx,sy,430,
                new int[]{0x00000000,0x22000000,0xbb00040c},
                new float[]{0f,.72f,1f},Shader.TileMode.CLAMP));
        c.drawCircle(sx,sy,430,p);p.setShader(null);
    }

    private void drawHud(Canvas c){
        int W=getWidth(),H=getHeight();
        box(c,12,10,W*.48f,78,15,0xcc03101f);
        txt(c,"PLANET ASSAULT  •  "+names[selectedPlanet],24,38,21,Color.WHITE,Paint.Align.LEFT);
        txt(c,"Scout the planet • Destroy defenses • Find and destroy Command Center",24,63,13,0xff8ddfff,Paint.Align.LEFT);
        box(c,W-235,12,W-12,76,15,0xcc03101f);
        txt(c,"MAP "+(int)playerX+","+(int)playerY,W-24,39,15,Color.WHITE,Paint.Align.RIGHT);
        txt(c,"Wingmen "+wingmen+"/3",W-24,62,13,0xffffd45a,Paint.Align.RIGHT);
        txt(c,"View "+(int)cameraYaw+"°  Tilt "+(int)(cameraPitch*100)+"%",W-24,82,12,0xff9fdcff,Paint.Align.RIGHT);
        menuButton(c,W-155,90,W-18,140,"RETREAT",0xff4d5964);
    }

    private void drawControls(Canvas c){
        int W=getWidth(),H=getHeight();
        float jx=118, jy=H-118, jr=78;
        // translucent left joystick - deliberately low opacity so it does not hide the battlefield
        p.setStyle(Paint.Style.FILL);p.setColor(0x442fdcff);c.drawCircle(jx,jy,jr,p);
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(3);p.setColor(0x995eeaff);c.drawCircle(jx,jy,jr,p);
        p.setStyle(Paint.Style.FILL);p.setColor(0x8869eaff);
        c.drawCircle(jx+joyX*jr*.72f,jy+joyY*jr*.72f,31,p);
        txt(c,"MOVE",jx,jy+jr+22,12,0xbbbdefff,Paint.Align.CENTER);

        float fx=W-105, fy=H-112;
        p.setStyle(Paint.Style.FILL);p.setColor(fireHeld?0xccff5a28:0x88ff5a28);c.drawCircle(fx,fy,58,p);
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(4);p.setColor(0xddffd0a0);c.drawCircle(fx,fy,58,p);
        txt(c,"FIRE",fx,fy+7,18,Color.WHITE,Paint.Align.CENTER);

        float mx=W-205,my=H-92;
        p.setStyle(Paint.Style.FILL);p.setColor(0x6651a8ff);c.drawCircle(mx,my,38,p);
        txt(c,"MISSILE",mx,my+5,10,Color.WHITE,Paint.Align.CENTER);

        txt(c,"Drag empty area to rotate / tilt camera",W/2f,H-18,12,0xaaaadfff,Paint.Align.CENTER);
    }

    private void menuButton(Canvas c,float l,float t,float r,float b,String s,int col){
        box(c,l,t,r,b,18,col);stroke(c,l,t,r,b,18,2,Color.WHITE);txt(c,s,(l+r)/2,(t+b)/2+7,18,Color.WHITE,Paint.Align.CENTER);
    }

    private void askPlanetName(){
        final EditText input=new EditText(getContext());input.setSingleLine();input.setText(planetName);input.selectAll();
        new AlertDialog.Builder(getContext()).setTitle("Name your home planet").setView(input)
                .setPositiveButton("SAVE",(d,w)->{String s=input.getText().toString().trim();if(!s.isEmpty())planetName=s;invalidate();})
                .setNegativeButton("CANCEL",null).show();
    }

    @Override public boolean onTouchEvent(MotionEvent e){
        int W=getWidth(),H=getHeight();
        int action=e.getActionMasked();
        int ai=e.getActionIndex();
        float x=e.getX(ai), y=e.getY(ai);

        if(mode!=ASSAULT){
            if(action!=MotionEvent.ACTION_DOWN)return true;
            if(mode==ORIGIN){
                if(y>H*.14f&&y<H*.74f){int i=(int)(x/(W/4f));selectedPlanet=Math.max(0,Math.min(3,i));invalidate();return true;}
                if(y>H*.78f&&y<H*.88f){askPlanetName();return true;}
                if(y>H*.88f){mode=BASE;invalidate();return true;}
            }else if(mode==BASE){
                if(x>W*.77f&&y>H*.80f){mode=LANDING;invalidate();return true;}
                if(x>W*.56f&&x<W*.76f&&y>H*.80f){
                    if(credits>=1000&&metal>=500){credits-=1000;metal-=500;baseLevel++;wingmen=Math.min(3,wingmen+1);}
                    invalidate();return true;
                }
            }else if(mode==LANDING){
                float cx=W*.5f,cy=H*.48f,rr=Math.min(W,H)*.36f;
                float[][] z={{cx,cy-rr*.78f},{cx+rr*.78f,cy},{cx,cy+rr*.78f},{cx-rr*.78f,cy}};
                for(int i=0;i<4;i++)if(Math.hypot(x-z[i][0],y-z[i][1])<70){landingZone=i;invalidate();return true;}
                if(y>H*.82f&&x>W*.35f&&x<W*.65f){startAssault();return true;}
                if(x<170&&y>H*.82f){mode=BASE;invalidate();return true;}
            }
            return true;
        }

        int pid=e.getPointerId(ai);
        float jcx=118f,jcy=H-118f,jr=92f;
        float fcx=W-105f,fcy=H-112f;

        if(action==MotionEvent.ACTION_DOWN || action==MotionEvent.ACTION_POINTER_DOWN){
            if(x>W-165&&y<155){mode=BASE;joystickPointer=cameraPointer=firePointer=-1;fireHeld=false;joyX=joyY=0;invalidate();return true;}
            if(Math.hypot(x-jcx,y-jcy)<jr*1.25f && joystickPointer==-1){
                joystickPointer=pid; updateJoystick(x,y,jcx,jcy,jr); return true;
            }
            if(Math.hypot(x-fcx,y-fcy)<76 && firePointer==-1){
                firePointer=pid;fireHeld=true;fireWeapon();invalidate();return true;
            }
            // Empty central/right-upper area controls the MMO camera, not the aircraft.
            if(cameraPointer==-1 && y>95 && y<H-185 && x>210 && x<W-190){
                cameraPointer=pid;camTouchX=x;camTouchY=y;return true;
            }
        }else if(action==MotionEvent.ACTION_MOVE){
            for(int i=0;i<e.getPointerCount();i++){
                int id=e.getPointerId(i);float px=e.getX(i),py=e.getY(i);
                if(id==joystickPointer)updateJoystick(px,py,jcx,jcy,jr);
                else if(id==cameraPointer){
                    float dx=px-camTouchX,dy=py-camTouchY;camTouchX=px;camTouchY=py;
                    cameraYaw=(cameraYaw+dx*.22f)%360f;
                    cameraPitch=clamp(cameraPitch-dy*.0022f,.58f,1.0f);
                }
            }
            invalidate();return true;
        }else if(action==MotionEvent.ACTION_UP || action==MotionEvent.ACTION_POINTER_UP || action==MotionEvent.ACTION_CANCEL){
            if(pid==joystickPointer){joystickPointer=-1;joyX=joyY=0f;}
            if(pid==cameraPointer)cameraPointer=-1;
            if(pid==firePointer){firePointer=-1;fireHeld=false;}
            if(action==MotionEvent.ACTION_CANCEL){joystickPointer=cameraPointer=firePointer=-1;joyX=joyY=0;fireHeld=false;}
            invalidate();return true;
        }
        return true;
    }

    private void updateJoystick(float x,float y,float cx,float cy,float r){
        float dx=x-cx,dy=y-cy,d=(float)Math.hypot(dx,dy);
        if(d>r){dx=dx/d*r;dy=dy/d*r;}
        joyX=dx/r;joyY=dy/r;
    }

    @Override public boolean performClick(){super.performClick();return true;}
}