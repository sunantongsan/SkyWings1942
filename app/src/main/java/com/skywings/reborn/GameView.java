package com.skywings.reborn;

import android.app.AlertDialog;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.*;
import android.view.MotionEvent;
import android.view.View;
import android.widget.EditText;
import java.util.ArrayList;
import java.util.Random;

public class GameView extends View {
    private static final int ORIGIN=0, BASE=1, GALAXY=2, BATTLE=3;
    private final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Random rnd=new Random(1942);
    private final SharedPreferences prefs;

    private Bitmap strategyArt, buildingAtlas;
    private int mode=ORIGIN, selectedPlanet=0, selectedBuilding=-1, selectedTroop=0;
    private String planetName="MyPlanet";
    private long credits=5000, metal=2500, crystal=800, oil=3000;
    private long lastEconomyTick=0;

    private final String[] planetNames={"AQUA","KAROS","NIVAR","VULCAN"};
    private final String[] buildingNames={
            "GALACTIC CORE","FUSION REACTOR","METAL EXTRACTOR","OIL PROCESSOR","CRYSTAL MINE",
            "RESOURCE VAULT","STAR HANGAR","RESEARCH LAB","LASER TOWER","SHIELD GENERATOR"};
    private final String[] buildingDesc={
            "Heart of your planet. Unlocks buildings and upgrades.",
            "Produces power required by your base.",
            "Produces Metal for construction and units.",
            "Processes Oil for advanced units and attacks.",
            "Harvests Crystal for research and high-tier upgrades.",
            "Protects and expands resource storage.",
            "Builds your fleet and increases unit capacity.",
            "Researches technology and improves all systems.",
            "Automatic defensive laser against attackers.",
            "Creates a defensive shield around nearby buildings."};
    private final int[] level=new int[10];

    // Base positions are normalized screen coordinates.
    private final float[][] basePos={
            {.50f,.48f},{.30f,.34f},{.18f,.58f},{.72f,.33f},{.82f,.58f},
            {.35f,.70f},{.63f,.72f},{.50f,.25f},{.16f,.28f},{.84f,.28f}};

    private static class EnemyBuilding {
        float x,y; int type,hp,maxHp; boolean dead;
        EnemyBuilding(float x,float y,int type,int hp){this.x=x;this.y=y;this.type=type;this.hp=this.maxHp=hp;}
    }
    private static class Unit {
        float x,y; int type,hp; float speed,damage,range;
        Unit(float x,float y,int type){
            this.x=x;this.y=y;this.type=type;
            if(type==0){hp=90;speed=2.8f;damage=6;range=32;}
            else if(type==1){hp=75;speed=2.3f;damage=12;range=42;}
            else if(type==2){hp=180;speed=1.55f;damage=9;range=36;}
            else {hp=60;speed=3.2f;damage=4;range=28;}
        }
    }

    private final ArrayList<EnemyBuilding> enemies=new ArrayList<>();
    private final ArrayList<Unit> units=new ArrayList<>();
    private int[] troopStock={8,4,3,6};
    private int battleDamage=0;
    private boolean battleWon=false;

    public GameView(Context c){
        super(c);
        setFocusable(true);setClickable(true);
        prefs=c.getSharedPreferences("galaxy1942_rts",Context.MODE_PRIVATE);
        strategyArt=BitmapFactory.decodeResource(getResources(),R.drawable.galaxy1942_strategy_art);
        buildingAtlas=BitmapFactory.decodeResource(getResources(),R.drawable.galaxy1942_buildings);
        for(int i=0;i<10;i++)level[i]=Math.max(1,prefs.getInt("b"+i,1));
        planetName=prefs.getString("planet_name","MyPlanet");
        selectedPlanet=prefs.getInt("planet_type",0);
        credits=prefs.getLong("credits",5000);
        metal=prefs.getLong("metal",2500);
        crystal=prefs.getLong("crystal",800);
        oil=prefs.getLong("oil",3000);
        boolean created=prefs.getBoolean("created",false);
        mode=created?BASE:ORIGIN;
        lastEconomyTick=System.currentTimeMillis();
    }

    private void save(){
        SharedPreferences.Editor e=prefs.edit()
                .putBoolean("created",true).putString("planet_name",planetName).putInt("planet_type",selectedPlanet)
                .putLong("credits",credits).putLong("metal",metal).putLong("crystal",crystal).putLong("oil",oil);
        for(int i=0;i<10;i++)e.putInt("b"+i,level[i]);
        e.apply();
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
        economyTick();
        if(mode==ORIGIN)drawOrigin(c);
        else if(mode==BASE)drawBase(c);
        else if(mode==GALAXY)drawGalaxy(c);
        else drawBattle(c);
        postInvalidateDelayed(33);
    }

    private void economyTick(){
        long now=System.currentTimeMillis();
        long secs=(now-lastEconomyTick)/1000;
        if(secs<=0)return;
        lastEconomyTick+=secs*1000;
        credits+=secs*(2+level[0]);
        metal+=secs*(1+level[2]);
        oil+=secs*(1+level[3]);
        crystal+=secs*Math.max(1,level[4]/2);
        long cap=10000L+level[5]*5000L;
        credits=Math.min(credits,cap*2);metal=Math.min(metal,cap);oil=Math.min(oil,cap);crystal=Math.min(crystal,cap/2);
    }

    private void drawOrigin(Canvas c){
        int W=getWidth(),H=getHeight();
        if(strategyArt!=null){
            int sw=strategyArt.getWidth()/2,sh=strategyArt.getHeight()/2;
            c.drawBitmap(strategyArt,new Rect(0,0,sw,sh),new RectF(0,0,W,H),p);
        }else c.drawColor(0xff020712);
        box(c,0,H*.76f,W,H,0,0xaa020812);
        txt(c,"CHOOSE YOUR HOME PLANET",W/2,52,28,Color.WHITE,Paint.Align.CENTER);
        for(int i=0;i<4;i++){
            float l=W*(.04f+i*.24f),r=l+W*.20f;
            if(i==selectedPlanet)stroke(c,l,H*.18f,r,H*.68f,18,5,0xff5de8ff);
        }
        box(c,W*.30f,H*.79f,W*.70f,H*.86f,14,0xdd061a31);
        txt(c,"PLANET NAME: "+planetName,W*.5f,H*.835f,17,Color.WHITE,Paint.Align.CENTER);
        box(c,W*.34f,H*.89f,W*.66f,H*.97f,18,0xffff7200);
        txt(c,"CREATE PLANET",W*.5f,H*.944f,25,Color.WHITE,Paint.Align.CENTER);
    }

    private void drawBase(Canvas c){
        int W=getWidth(),H=getHeight();
        drawTerrain(c);
        drawTopBar(c,"HOME PLANET • "+planetName);

        for(int i=0;i<10;i++){
            float x=W*basePos[i][0], y=H*basePos[i][1];
            drawBuildingSprite(c,i,x,y,i==selectedBuilding?1.18f:1f);
            txt(c,"Lv."+level[i],x,y+61,12,Color.WHITE,Paint.Align.CENTER);
            if(i==selectedBuilding)stroke(c,x-66,y-55,x+66,y+62,16,3,0xff62eaff);
        }

        // left menu
        sideButton(c,15,H*.23f,140,H*.31f,"BASE");
        sideButton(c,15,H*.33f,140,H*.41f,"ARMY");
        sideButton(c,15,H*.43f,140,H*.51f,"DEFENSE");
        sideButton(c,15,H*.53f,140,H*.61f,"RESEARCH");

        box(c,W-235,H*.18f,W-15,H*.56f,16,0xcc06111e);
        txt(c,"PLANET STATUS",W-125,H*.225f,17,0xff8de8ff,Paint.Align.CENTER);
        txt(c,"Power  "+(100+level[1]*80),W-220,H*.29f,14,Color.WHITE,Paint.Align.LEFT);
        txt(c,"Storage  "+(10+level[5]*5)+"K",W-220,H*.34f,14,Color.WHITE,Paint.Align.LEFT);
        txt(c,"Fleet Cap  "+(8+level[6]*3),W-220,H*.39f,14,Color.WHITE,Paint.Align.LEFT);
        txt(c,"Defense  "+(level[8]*120+level[9]*100),W-220,H*.44f,14,Color.WHITE,Paint.Align.LEFT);
        txt(c,"Tech Lv. "+level[7],W-220,H*.49f,14,Color.WHITE,Paint.Align.LEFT);

        if(selectedBuilding>=0)drawBuildingPanel(c);
        else{
            box(c,W*.30f,H*.86f,W*.70f,H*.97f,18,0xff145f99);
            txt(c,"GALAXY MAP",W*.5f,H*.93f,22,Color.WHITE,Paint.Align.CENTER);
        }
    }

    private void drawTerrain(Canvas c){
        int W=getWidth(),H=getHeight();
        p.setShader(new LinearGradient(0,0,W,H,0xff183726,0xff102239,Shader.TileMode.CLAMP));
        c.drawRect(0,0,W,H,p);p.setShader(null);
        p.setColor(0x3343c7aa);p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(1);
        for(int x=0;x<W;x+=52)c.drawLine(x,78,x,H,p);
        for(int y=78;y<H;y+=52)c.drawLine(0,y,W,y,p);
        p.setStyle(Paint.Style.FILL);p.setColor(0x551d546e);
        Path coast=new Path();coast.moveTo(0,H*.78f);coast.lineTo(W*.25f,H*.72f);coast.lineTo(W*.48f,H*.80f);coast.lineTo(W*.68f,H*.73f);coast.lineTo(W,H*.79f);coast.lineTo(W,H);coast.lineTo(0,H);coast.close();c.drawPath(coast,p);
    }

    private void drawTopBar(Canvas c,String title){
        int W=getWidth();
        box(c,10,8,W-10,70,16,0xdd03101e);
        txt(c,title,26,45,24,Color.WHITE,Paint.Align.LEFT);
        txt(c,"¢ "+credits+"   METAL "+metal+"   OIL "+oil+"   CRYSTAL "+crystal,W-24,43,15,0xffffd56a,Paint.Align.RIGHT);
    }

    private void sideButton(Canvas c,float l,float t,float r,float b,String s){
        box(c,l,t,r,b,14,0xaa0a3151);stroke(c,l,t,r,b,14,2,0xff398bc2);txt(c,s,(l+r)/2,(t+b)/2+6,14,Color.WHITE,Paint.Align.CENTER);
    }

    private void drawBuildingPanel(Canvas c){
        int W=getWidth(),H=getHeight(),i=selectedBuilding;
        box(c,W*.22f,H*.79f,W*.78f,H*.98f,16,0xee06111e);
        drawBuildingSprite(c,i,W*.28f,H*.885f,.72f);
        txt(c,buildingNames[i],W*.35f,H*.835f,18,0xff7eeaff,Paint.Align.LEFT);
        txt(c,buildingDesc[i],W*.35f,H*.875f,13,Color.WHITE,Paint.Align.LEFT);
        txt(c,"LEVEL "+level[i]+"  •  Upgrade cost: "+upgradeCost(i)+" Metal",W*.35f,H*.915f,13,0xffffd66a,Paint.Align.LEFT);
        box(c,W*.62f,H*.925f,W*.755f,H*.972f,12,0xff1f8d42);
        txt(c,"UPGRADE",W*.687f,H*.957f,14,Color.WHITE,Paint.Align.CENTER);
    }

    private int upgradeCost(int type){return 300+level[type]*250+(type==0?400:0);}

    private void drawBuildingSprite(Canvas c,int type,float x,float y,float scale){
        if(buildingAtlas==null||buildingAtlas.isRecycled()){
            p.setStyle(Paint.Style.FILL);p.setColor(0xff25435a);c.drawCircle(x,y,45*scale,p);return;
        }
        int[] xs={0,307,614,921,1228};
        int col=type%5,row=type/5;
        int l=xs[col],r=(col==4?1536:xs[col+1]);
        int t=row==0?35:548;
        int b=row==0?430:882;
        Rect src=new Rect(l,t,r,b);
        float h=112*scale,w=h*(src.width()/(float)src.height());
        p.setFilterBitmap(true);p.setAlpha(255);
        c.drawBitmap(buildingAtlas,src,new RectF(x-w/2,y-h/2,x+w/2,y+h/2),p);
    }

    private void drawGalaxy(Canvas c){
        int W=getWidth(),H=getHeight();
        c.drawColor(0xff020715);
        p.setColor(0xffffffff);p.setStyle(Paint.Style.FILL);
        for(int i=0;i<90;i++)c.drawCircle((i*173)%W,(i*97)%H,1+(i%2),p);
        drawTopBar(c,"GALAXY MAP • OFFLINE SECTOR");
        txt(c,"Choose an AI planet to raid for resources",W/2,105,16,0xff8ddfff,Paint.Align.CENTER);
        float[][] ps={{.18f,.32f},{.38f,.26f},{.58f,.34f},{.78f,.25f},{.28f,.58f},{.50f,.55f},{.72f,.58f},{.18f,.78f},{.44f,.78f},{.76f,.77f}};
        int[] cols={0xff44aaff,0xffff9a43,0xff80d9ff,0xffff5544,0xff62d47f,0xff8b7cff,0xffffc75a,0xff5cc4e8,0xffb25cff,0xff8390a0};
        for(int i=0;i<10;i++){
            float x=W*ps[i][0],y=H*ps[i][1],rr=26+(i%3)*5;
            p.setShader(new RadialGradient(x-8,y-8,rr,new int[]{0xffffffff,cols[i],0xff06101e},null,Shader.TileMode.CLAMP));c.drawCircle(x,y,rr,p);p.setShader(null);
            txt(c,"A-"+String.format("%02d",i+1),x,y+rr+20,13,Color.WHITE,Paint.Align.CENTER);
        }
        box(c,18,H-64,140,H-16,14,0xff33495c);txt(c,"BACK",79,H-33,15,Color.WHITE,Paint.Align.CENTER);
    }

    private void setupBattle(int idx){
        mode=BATTLE;enemies.clear();units.clear();battleDamage=0;battleWon=false;
        troopStock=new int[]{8+level[6],4+level[6]/2,3+level[6]/2,6+level[6]};
        // enemy base occupies upper half
        enemies.add(new EnemyBuilding(.50f,.22f,0,380+idx*25));
        enemies.add(new EnemyBuilding(.30f,.30f,8,180+idx*20));
        enemies.add(new EnemyBuilding(.70f,.31f,8,180+idx*20));
        enemies.add(new EnemyBuilding(.40f,.42f,9,220+idx*20));
        enemies.add(new EnemyBuilding(.62f,.43f,6,150+idx*15));
        enemies.add(new EnemyBuilding(.23f,.45f,2,130+idx*12));
        enemies.add(new EnemyBuilding(.77f,.47f,3,130+idx*12));
    }

    private void drawBattle(Canvas c){
        int W=getWidth(),H=getHeight();
        updateBattle();
        p.setShader(new LinearGradient(0,0,W,H,0xff3d2d1e,0xff172633,Shader.TileMode.CLAMP));c.drawRect(0,0,W,H,p);p.setShader(null);
        drawTopBar(c,"RAID • AI PLANET");
        p.setColor(0x33444444);p.setStyle(Paint.Style.FILL);c.drawRect(0,H*.58f,W,H,p);

        int alive=0,total=0;
        for(EnemyBuilding e:enemies){
            total+=e.maxHp;if(!e.dead)alive+=Math.max(0,e.hp);
            if(e.dead)continue;
            float x=W*e.x,y=H*e.y;
            drawBuildingSprite(c,e.type,x,y,e.type==0?1.05f:.72f);
            float bw=72f;
            p.setColor(0xbb101010);c.drawRect(x-bw/2,y+48,x+bw/2,y+55,p);
            p.setColor(0xff59e66c);c.drawRect(x-bw/2,y+48,x-bw/2+bw*(e.hp/(float)e.maxHp),y+55,p);
        }
        battleDamage=total==0?0:(int)(100f*(total-alive)/total);

        for(Unit u:units)drawUnit(c,u);

        box(c,10,H*.78f,W-10,H-10,18,0xdd04101c);
        txt(c,"DAMAGE "+battleDamage+"%",W*.5f,H*.815f,18,Color.WHITE,Paint.Align.CENTER);
        String[] names={"FIGHTER","BOMBER","HEAVY","DRONE"};
        for(int i=0;i<4;i++){
            float l=W*(.16f+i*.17f),r=l+W*.145f;
            box(c,l,H*.84f,r,H*.965f,14,i==selectedTroop?0xff216e9b:0xff12334a);
            txt(c,names[i],(l+r)/2,H*.89f,13,Color.WHITE,Paint.Align.CENTER);
            txt(c,"x"+troopStock[i],(l+r)/2,H*.94f,14,0xffffd65c,Paint.Align.CENTER);
        }
        box(c,18,H*.84f,130,H*.965f,14,0xff4b5964);txt(c,"RETREAT",74,H*.91f,13,Color.WHITE,Paint.Align.CENTER);

        if(battleWon){
            box(c,W*.30f,H*.31f,W*.70f,H*.61f,24,0xee05111f);
            txt(c,"VICTORY",W/2,H*.39f,34,0xffffd65a,Paint.Align.CENTER);
            txt(c,"Loot secured: Credits +1200  Metal +700  Oil +500",W/2,H*.47f,16,Color.WHITE,Paint.Align.CENTER);
            txt(c,"Tap to return home",W/2,H*.55f,14,0xff8de8ff,Paint.Align.CENTER);
        }
    }

    private void drawUnit(Canvas c,Unit u){
        int W=getWidth(),H=getHeight();float x=W*u.x,y=H*u.y;
        Path q=new Path();q.moveTo(x,y-16);q.lineTo(x-13,y+12);q.lineTo(x,y+6);q.lineTo(x+13,y+12);q.close();
        int[] col={0xff62dfff,0xffff654f,0xffffc54c,0xffa884ff};
        p.setColor(col[u.type]);p.setStyle(Paint.Style.FILL);c.drawPath(q,p);
    }

    private void updateBattle(){
        if(battleWon)return;
        boolean anyEnemy=false;
        for(EnemyBuilding e:enemies)if(!e.dead)anyEnemy=true;
        if(!anyEnemy){
            battleWon=true;credits+=1200;metal+=700;oil+=500;crystal+=90;save();return;
        }
        for(Unit u:units){
            EnemyBuilding target=null;float best=999f;
            for(EnemyBuilding e:enemies){
                if(e.dead)continue;
                float dx=e.x-u.x,dy=e.y-u.y,d=(float)Math.hypot(dx,dy);
                if(d<best){best=d;target=e;}
            }
            if(target==null)continue;
            if(best>.045f){
                float dx=target.x-u.x,dy=target.y-u.y,d=Math.max(.001f,(float)Math.hypot(dx,dy));
                u.x+=dx/d*u.speed*.00055f;u.y+=dy/d*u.speed*.00055f;
            }else{
                target.hp-=Math.max(1,(int)u.damage);
                if(target.hp<=0)target.dead=true;
            }
        }
    }

    private void deploy(float x,float y){
        if(selectedTroop<0||selectedTroop>3||troopStock[selectedTroop]<=0)return;
        // deployment zone only bottom 40%
        if(y<.58f)return;
        units.add(new Unit(x,y,selectedTroop));troopStock[selectedTroop]--;
    }

    private void askPlanetName(){
        EditText input=new EditText(getContext());input.setSingleLine();input.setText(planetName);input.selectAll();
        new AlertDialog.Builder(getContext()).setTitle("Name your home planet").setView(input)
                .setPositiveButton("SAVE",(d,w)->{String s=input.getText().toString().trim();if(!s.isEmpty())planetName=s;invalidate();})
                .setNegativeButton("CANCEL",null).show();
    }

    @Override public boolean onTouchEvent(MotionEvent e){
        if(e.getActionMasked()!=MotionEvent.ACTION_DOWN)return true;
        float x=e.getX(),y=e.getY();int W=getWidth(),H=getHeight();

        if(mode==ORIGIN){
            if(y>H*.15f&&y<H*.70f){selectedPlanet=Math.max(0,Math.min(3,(int)(x/(W/4f))));invalidate();return true;}
            if(y>H*.77f&&y<H*.88f){askPlanetName();return true;}
            if(y>H*.88f){mode=BASE;save();invalidate();return true;}
        }else if(mode==BASE){
            // building selection
            for(int i=0;i<10;i++){
                float bx=W*basePos[i][0],by=H*basePos[i][1];
                if(Math.hypot(x-bx,y-by)<72){selectedBuilding=i;invalidate();return true;}
            }
            if(selectedBuilding>=0 && x>W*.61f&&x<W*.77f&&y>H*.91f){
                int cost=upgradeCost(selectedBuilding);
                if(metal>=cost){metal-=cost;level[selectedBuilding]++;save();}
                invalidate();return true;
            }
            if(selectedBuilding<0 && x>W*.29f&&x<W*.71f&&y>H*.84f){mode=GALAXY;invalidate();return true;}
            if(y>H*.74f&&x<W*.2f){selectedBuilding=-1;invalidate();return true;}
            selectedBuilding=-1;invalidate();
        }else if(mode==GALAXY){
            if(x<155&&y>H-80){mode=BASE;invalidate();return true;}
            float[][] ps={{.18f,.32f},{.38f,.26f},{.58f,.34f},{.78f,.25f},{.28f,.58f},{.50f,.55f},{.72f,.58f},{.18f,.78f},{.44f,.78f},{.76f,.77f}};
            for(int i=0;i<10;i++)if(Math.hypot(x-W*ps[i][0],y-H*ps[i][1])<55){setupBattle(i);invalidate();return true;}
        }else{
            if(battleWon){mode=BASE;invalidate();return true;}
            if(x<145&&y>H*.80f){mode=BASE;invalidate();return true;}
            if(y>H*.82f){
                for(int i=0;i<4;i++){
                    float l=W*(.16f+i*.17f),r=l+W*.145f;
                    if(x>l&&x<r){selectedTroop=i;invalidate();return true;}
                }
            }else deploy(x/W,y/H);
        }
        return true;
    }

    @Override public boolean performClick(){super.performClick();return true;}
}