package com.skywings.reborn;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.graphics.*;
import android.view.MotionEvent;
import android.view.View;
import android.widget.EditText;
import java.util.Random;

public class GameView extends View {
    private static final int ORIGIN=0, BASE=1, ASSAULT=2;
    private final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Random rnd=new Random();
    private Bitmap strategyArt, playerAtlas;
    private int mode=ORIGIN, selectedPlanet=0;
    private String planetName="MyPlanet";
    private int credits=5000, metal=2500, crystal=800, oil=3000;
    private int baseLevel=1, wingmen=0;
    private float playerX=180, playerY=420;
    private final String[] names={"OCEAN WORLD","DESERT WORLD","ICE WORLD","FOREST WORLD"};
    private final int[] colors={Color.CYAN,0xffff9a45,0xff9fdcff,0xff66e58c};

    public GameView(Context c){
        super(c);
        setFocusable(true); setClickable(true);
        strategyArt=BitmapFactory.decodeResource(getResources(),R.drawable.galaxy1942_strategy_art);
        playerAtlas=BitmapFactory.decodeResource(getResources(),R.drawable.player_atlas);
    }
    private void txt(Canvas c,String s,float x,float y,float z,int color,Paint.Align a){
        p.setShader(null);p.setStyle(Paint.Style.FILL);p.setColor(color);p.setTextAlign(a);
        p.setTypeface(Typeface.create("sans",Typeface.BOLD));p.setTextSize(z);c.drawText(s,x,y,p);
    }
    private void box(Canvas c,float l,float t,float r,float b,float rad,int color){
        p.setShader(null);p.setStyle(Paint.Style.FILL);p.setColor(color);c.drawRoundRect(l,t,r,b,rad,rad,p);
    }
    private void stroke(Canvas c,float l,float t,float r,float b,float rad,float sw,int color){
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(sw);p.setColor(color);c.drawRoundRect(l,t,r,b,rad,rad,p);
    }
    private void drawArtPanel(Canvas c,int panel){
        int W=getWidth(),H=getHeight();
        if(strategyArt==null || strategyArt.isRecycled()){
            c.drawColor(0xff030814);
            txt(c,"ARTWORK LOAD FAILED",W/2,H/2,32,Color.RED,Paint.Align.CENTER);
            return;
        }
        int sw=strategyArt.getWidth()/2, sh=strategyArt.getHeight()/2;
        int sx=(panel%2)*sw, sy=(panel/2)*sh;
        Rect src=new Rect(sx,sy,sx+sw,sy+sh);
        p.setAlpha(255); p.setFilterBitmap(true); p.setStyle(Paint.Style.FILL);
        c.drawBitmap(strategyArt,src,new RectF(0,0,W,H),p);
    }
    @Override protected void onDraw(Canvas c){
        if(mode==ORIGIN) drawOrigin(c); else if(mode==BASE) drawBase(c); else drawAssault(c);
    }
    private void drawOrigin(Canvas c){
        int W=getWidth(),H=getHeight();
        p.setStyle(Paint.Style.FILL);
        drawArtPanel(c,0);
        box(c,0,H*.79f,W,H,0,0xbb030814);
        float gap=W*.015f,left=W*.025f,cw=(W*.95f-gap*3)/4f;
        for(int i=0;i<4;i++){
            float l=left+i*(cw+gap),r=l+cw;
            if(i==selectedPlanet)stroke(c,l,H*.23f,r,H*.70f,18,5,0xff69eaff);
        }
        box(c,W*.28f,H*.805f,W*.72f,H*.875f,16,0xdd071a31);
        stroke(c,W*.28f,H*.805f,W*.72f,H*.875f,16,2,0xff55cfff);
        txt(c,"PLANET NAME: "+planetName,W*.5f,H*.85f,18,Color.WHITE,Paint.Align.CENTER);
        p.setShader(new LinearGradient(W*.30f,H*.89f,W*.70f,H*.97f,0xffffb200,0xffff4e00,Shader.TileMode.CLAMP));
        c.drawRoundRect(W*.30f,H*.89f,W*.70f,H*.97f,22,22,p);p.setShader(null);
        txt(c,"START GAME",W*.5f,H*.943f,28,Color.WHITE,Paint.Align.CENTER);
    }
    private void drawBase(Canvas c){
        int W=getWidth(),H=getHeight();
        drawArtPanel(c,1);
        box(c,0,0,W,H,0,0x33020814);
        box(c,16,14,W-16,74,16,0xaa03101f);
        txt(c,planetName+"  •  HOME PLANET",30,50,28,Color.WHITE,Paint.Align.LEFT);
        txt(c,"Credits "+credits+"   Metal "+metal+"   Crystal "+crystal+"   Oil "+oil,W-30,45,17,0xffffd45a,Paint.Align.RIGHT);
        // terrain grid
        p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(1);p.setColor(0x1844ddaa);
        for(int x=0;x<W;x+=48)c.drawLine(x,80,x,H,p); for(int y=80;y<H;y+=48)c.drawLine(0,y,W,y,p);
        drawBuilding(c,W*.50f,H*.45f,"COMMAND",0xff40bfff);
        drawBuilding(c,W*.33f,H*.31f,"HANGAR",0xff8d7cff);
        drawBuilding(c,W*.70f,H*.31f,"REFINERY",0xffffa43a);
        drawBuilding(c,W*.28f,H*.56f,"DEFENSE",0xffff5a63);
        txt(c,"Base Lv."+baseLevel+"   Wingmen "+wingmen+"/3",30,H-34,18,Color.WHITE,Paint.Align.LEFT);
        menuButton(c,W*.58f,H*.82f,W*.76f,H*.94f,"UPGRADE",0xff1b7e9f);
        menuButton(c,W*.78f,H*.82f,W*.97f,H*.94f,"INVADE",0xffb6531c);
    }
    private void drawBuilding(Canvas c,float x,float y,String name,int col){
        box(c,x-60,y-42,x+60,y+42,12,0xdd0c1723);stroke(c,x-60,y-42,x+60,y+42,12,3,col);
        txt(c,name,x,y+6,14,Color.WHITE,Paint.Align.CENTER);
    }
    private void menuButton(Canvas c,float l,float t,float r,float b,String s,int col){
        box(c,l,t,r,b,18,col);stroke(c,l,t,r,b,18,2,Color.WHITE);txt(c,s,(l+r)/2,(t+b)/2+7,18,Color.WHITE,Paint.Align.CENTER);
    }
    private void drawAssault(Canvas c){
        int W=getWidth(),H=getHeight();
        drawArtPanel(c,3);
        box(c,0,0,W,H,0,0x22031216);
        p.setStyle(Paint.Style.FILL);p.setColor(0x99396b39);c.drawRect(0,H*.18f,W,H*.62f,p);
        p.setColor(0xaa255b7a);c.drawRect(0,H*.63f,W,H,p);
        // roads and enemy city
        p.setColor(0xff4b4b48);c.drawRect(W*.10f,H*.46f,W*.90f,H*.57f,p);
        txt(c,"ENEMY CITY",W*.82f,H*.18f,24,Color.WHITE,Paint.Align.CENTER);
        drawDefense(c,W*.70f,H*.35f,"AA");drawDefense(c,W*.82f,H*.38f,"SAM");drawDefense(c,W*.74f,H*.18f,"DRONE");
        drawDefense(c,W*.90f,H*.22f,"HQ");
        // player and wingmen
        drawFighter(c,playerX,playerY,0xff65e8ff,1.2f);
        for(int i=0;i<wingmen;i++)drawFighter(c,playerX-55-i*45,playerY+50,0xff9effff,.7f);
        box(c,16,10,W*.48f,78,16,0xaa03101f);
        txt(c,"ASSAULT "+names[selectedPlanet],25,35,22,Color.WHITE,Paint.Align.LEFT);
        txt(c,"Loot: Credits / Metal / Crystal / Oil",25,62,14,0xffffdc68,Paint.Align.LEFT);
        menuButton(c,20,H-74,150,H-18,"RETREAT",0xff4d5964);
        invalidate();
    }
    private void drawDefense(Canvas c,float x,float y,String s){
        box(c,x-34,y-28,x+34,y+28,8,0xff301414);stroke(c,x-34,y-28,x+34,y+28,8,2,0xffff5656);txt(c,s,x,y+5,13,Color.WHITE,Paint.Align.CENTER);
    }
    private void drawFighter(Canvas c,float x,float y,int col,float sc){
        if(playerAtlas!=null && !playerAtlas.isRecycled()){
            int w=playerAtlas.getWidth()/5;
            int idx=Math.max(0,Math.min(4,selectedPlanet));
            Rect src=new Rect(idx*w,0,(idx==4?playerAtlas.getWidth():(idx+1)*w),playerAtlas.getHeight());
            float h=92f*sc, ww=h*(src.width()/(float)Math.max(1,src.height()));
            p.setAlpha(255); p.setFilterBitmap(true);
            c.drawBitmap(playerAtlas,src,new RectF(x-ww/2,y-h/2,x+ww/2,y+h/2),p);
            return;
        }
        Path q=new Path();q.moveTo(x,y-34*sc);q.lineTo(x-28*sc,y+24*sc);q.lineTo(x,y+10*sc);q.lineTo(x+28*sc,y+24*sc);q.close();
        p.setColor(col);p.setStyle(Paint.Style.FILL);c.drawPath(q,p);
    }
    private void askPlanetName(){
        final EditText input=new EditText(getContext());input.setSingleLine();input.setText(planetName);input.selectAll();
        new AlertDialog.Builder(getContext()).setTitle("Name your home planet").setView(input)
          .setPositiveButton("SAVE",(d,w)->{String s=input.getText().toString().trim();if(!s.isEmpty())planetName=s;invalidate();})
          .setNegativeButton("CANCEL",null).show();
    }
    @Override public boolean onTouchEvent(MotionEvent e){
        if(e.getActionMasked()!=MotionEvent.ACTION_DOWN && e.getActionMasked()!=MotionEvent.ACTION_MOVE)return true;
        float x=e.getX(),y=e.getY();int W=getWidth(),H=getHeight();
        if(mode==ORIGIN && e.getActionMasked()==MotionEvent.ACTION_DOWN){
            if(y>H*.20f&&y<H*.72f){int i=(int)(x/(W/4f));selectedPlanet=Math.max(0,Math.min(3,i));invalidate();return true;}
            if(y>H*.79f&&y<H*.885f){askPlanetName();return true;}
            if(y>H*.88f){mode=BASE;invalidate();return true;}
        } else if(mode==BASE && e.getActionMasked()==MotionEvent.ACTION_DOWN){
            if(x>W*.78f&&y>H*.80f){mode=ASSAULT;playerX=W*.20f;playerY=H*.45f;invalidate();return true;}
            if(x>W*.58f&&x<W*.77f&&y>H*.80f){if(credits>=1000&&metal>=500){credits-=1000;metal-=500;baseLevel++;wingmen=Math.min(3,wingmen+1);}invalidate();return true;}
        } else if(mode==ASSAULT){
            if(e.getActionMasked()==MotionEvent.ACTION_MOVE){playerX=x;playerY=y;invalidate();}
            else if(x<170&&y>H-90){mode=BASE;invalidate();}
        }
        return true;
    }
    @Override public boolean performClick(){super.performClick();return true;}
}