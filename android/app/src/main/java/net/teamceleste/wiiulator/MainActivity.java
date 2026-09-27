package net.teamceleste.wiiulator;

import android.app.*;
import android.os.*;
import android.content.*;
import android.content.res.ColorStateList;
import android.graphics.*;
import android.net.Uri;
import android.view.*;
import android.widget.*;
import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.google.android.material.button.MaterialButton;
import com.google.android.material.card.MaterialCardView;
import com.google.android.material.color.DynamicColors;
import com.google.android.material.color.MaterialColors;
import com.google.android.material.floatingactionbutton.FloatingActionButton;
import com.google.android.material.materialswitch.MaterialSwitch;
import java.io.*;
import java.util.*;

public final class MainActivity extends Activity {
    private LinearLayout content;
    private int BG, SURFACE, PRIMARY, TEXT, MUTED;
    private final ArrayList<Game> games = new ArrayList<>();
    private final HashSet<String> favorites = new HashSet<>();
    private android.content.SharedPreferences prefs;
    private static final int PICK = 7;

    private static final class Game {
        final String name, provider, version;
        Game(String n, String p, String v) { name=n; provider=p; version=v; }
    }

    @Override public void onCreate(Bundle b) {
        super.onCreate(b);
        DynamicColors.applyToActivityIfAvailable(this);
        BG = MaterialColors.getColor(this, android.R.attr.colorBackground, Color.rgb(248,248,248));
        PRIMARY = MaterialColors.getColor(this, android.R.attr.colorAccent, Color.rgb(60,90,255));
        TEXT = MaterialColors.getColor(this, android.R.attr.textColorPrimary, Color.BLACK);
        MUTED = MaterialColors.getColor(this, android.R.attr.textColorSecondary, Color.DKGRAY);
        SURFACE = blend(BG, Color.WHITE, 0.55f);
        prefs = getSharedPreferences("wiiulator", MODE_PRIVATE);
        setRequestedOrientation(android.content.pm.ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED);
        buildShell();
        showLibrary();
    }

    private int blend(int a,int b,float amount) {
        return Color.rgb(
            (int)(Color.red(a)+(Color.red(b)-Color.red(a))*amount),
            (int)(Color.green(a)+(Color.green(b)-Color.green(a))*amount),
            (int)(Color.blue(a)+(Color.blue(b)-Color.blue(a))*amount)
        );
    }

    private int dp(int v) { return (int)(v * getResources().getDisplayMetrics().density + .5f); }

    private TextView text(String value,float size,int color) {
        TextView t=new TextView(this);
        t.setText(value); t.setTextSize(size); t.setTextColor(color);
        t.setGravity(Gravity.CENTER_VERTICAL);
        return t;
    }

    private MaterialCardView card() {
        MaterialCardView c=new MaterialCardView(this);
        c.setCardBackgroundColor(SURFACE);
        c.setRadius(dp(20));
        c.setStrokeWidth(dp(1));
        c.setStrokeColor(blend(BG,Color.GRAY,.15f));
        c.setUseCompatPadding(false);
        return c;
    }

    private MaterialButton button(String label, int icon) {
        MaterialButton b=new MaterialButton(this);
        b.setText(label);
        b.setAllCaps(false);
        b.setTextSize(14);
        b.setIconResource(icon);
        b.setIconGravity(MaterialButton.ICON_GRAVITY_TEXT_START);
        b.setIconPadding(dp(8));
        b.setCornerRadius(dp(14));
        b.setBackgroundTintList(ColorStateList.valueOf(PRIMARY));
        b.setTextColor(Color.WHITE);
        b.setPadding(dp(16),0,dp(16),0);
        return b;
    }

    private void buildShell() {
        LinearLayout root=new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(BG);

        LinearLayout appbar=new LinearLayout(this);
        appbar.setOrientation(LinearLayout.VERTICAL);
        appbar.setPadding(dp(20),dp(18),dp(20),dp(10));
        TextView brand=text("WiiUlator",24,TEXT);
        brand.setTypeface(Typeface.DEFAULT,Typeface.BOLD);
        appbar.addView(brand,new LinearLayout.LayoutParams(-1,dp(34)));
        TextView sub=text("Wii U emulation for Android",13,MUTED);
        appbar.addView(sub,new LinearLayout.LayoutParams(-1,dp(24)));
        root.addView(appbar);

        FrameLayout frame=new FrameLayout(this);
        content=new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        ScrollView scroll=new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.addView(content);
        frame.addView(scroll,new FrameLayout.LayoutParams(-1,-1));
        root.addView(frame,new LinearLayout.LayoutParams(-1,0,1));

        BottomNavigationView nav=new BottomNavigationView(this);
        nav.getMenu().add(0,1,0,"Library").setIcon(net.teamceleste.wiiulator.R.drawable.ic_library);
        nav.getMenu().add(0,2,1,"Favorites").setIcon(net.teamceleste.wiiulator.R.drawable.ic_star);
        nav.getMenu().add(0,3,2,"Settings").setIcon(net.teamceleste.wiiulator.R.drawable.ic_settings);
        nav.setLabelVisibilityMode(BottomNavigationView.LABEL_VISIBILITY_LABELED);
        nav.setOnItemSelectedListener(item -> {
            if(item.getItemId()==1) showLibrary();
            else if(item.getItemId()==2) showFavorites();
            else showSettings();
            return true;
        });
        nav.setSelectedItemId(1);
        root.addView(nav,new LinearLayout.LayoutParams(-1,-2));
        setContentView(root);
    }

    private void resetContent() {
        content.removeAllViews();
        content.setPadding(dp(16),dp(4),dp(16),dp(20));
    }

    private TextView section(String title) {
        TextView t=text(title,12,PRIMARY);
        t.setTypeface(Typeface.DEFAULT,Typeface.BOLD);
        t.setPadding(dp(4),dp(20),dp(4),dp(8));
        content.addView(t,new LinearLayout.LayoutParams(-1,dp(42)));
        return t;
    }

    private void addGap(int h) {
        Space s=new Space(this);
        content.addView(s,new LinearLayout.LayoutParams(1,dp(h)));
    }

    private void showLibrary() {
        resetContent();

        LinearLayout titleRow=new LinearLayout(this);
        titleRow.setGravity(Gravity.CENTER_VERTICAL);
        TextView title=text("Library",30,TEXT);
        title.setTypeface(Typeface.DEFAULT,Typeface.BOLD);
        titleRow.addView(title,new LinearLayout.LayoutParams(0,dp(48),1));
        TextView count=text(games.size()+" games",13,MUTED);
        count.setGravity(Gravity.CENTER);
        titleRow.addView(count,new LinearLayout.LayoutParams(dp(82),dp(36)));
        content.addView(titleRow);

        TextView hint=text("Import Wii U software and launch it from here.",14,MUTED);
        content.addView(hint,new LinearLayout.LayoutParams(-1,dp(30)));

        if(games.isEmpty()) {
            addGap(18);
            MaterialCardView empty=card();
            LinearLayout box=new LinearLayout(this);
            box.setOrientation(LinearLayout.VERTICAL);
            box.setGravity(Gravity.CENTER_HORIZONTAL);
            box.setPadding(dp(24),dp(30),dp(24),dp(26));
            ImageView icon=new ImageView(this);
            icon.setImageResource(net.teamceleste.wiiulator.R.drawable.ic_library);
            icon.setBackgroundTintList(ColorStateList.valueOf(PRIMARY));
            box.addView(icon,new LinearLayout.LayoutParams(dp(48),dp(48)));
            TextView t=text("Your library is empty",21,TEXT);
            t.setGravity(Gravity.CENTER);
            t.setTypeface(Typeface.DEFAULT,Typeface.BOLD);
            box.addView(t,new LinearLayout.LayoutParams(-1,dp(40)));
            TextView s=text("Choose a Wii U game or executable to add it to WiiUlator.",14,MUTED);
            s.setGravity(Gravity.CENTER);
            box.addView(s,new LinearLayout.LayoutParams(-1,dp(55)));
            MaterialButton imp=button("Import game",net.teamceleste.wiiulator.R.drawable.ic_add);
            imp.setOnClickListener(v->openPicker());
            LinearLayout.LayoutParams ip=new LinearLayout.LayoutParams(-1,dp(52));
            ip.topMargin=dp(8);
            box.addView(imp,ip);
            empty.addView(box);
            content.addView(empty,new LinearLayout.LayoutParams(-1,-2));
            return;
        }

        addGap(12);
        for(Game g:games) addGameCard(g);
    }

    private void addGameCard(Game g) {
        MaterialCardView c=card();
        LinearLayout outer=new LinearLayout(this);
        outer.setOrientation(LinearLayout.VERTICAL);
        outer.setPadding(dp(16),dp(16),dp(16),dp(14));

        LinearLayout row=new LinearLayout(this);
        row.setGravity(Gravity.CENTER_VERTICAL);
        TextView badge=text("WII U",12,Color.WHITE);
        badge.setGravity(Gravity.CENTER);
        badge.setTypeface(Typeface.DEFAULT,Typeface.BOLD);
        badge.setBackgroundColor(PRIMARY);
        row.addView(badge,new LinearLayout.LayoutParams(dp(58),dp(58)));

        LinearLayout info=new LinearLayout(this);
        info.setOrientation(LinearLayout.VERTICAL);
        info.setPadding(dp(14),0,dp(8),0);
        TextView n=text(g.name,18,TEXT);
        n.setTypeface(Typeface.DEFAULT,Typeface.BOLD);
        TextView p=text(g.provider,13,MUTED);
        TextView v=text(g.version.isEmpty()?"Ready":g.version,12,PRIMARY);
        info.addView(n,new LinearLayout.LayoutParams(-1,dp(28)));
        info.addView(p,new LinearLayout.LayoutParams(-1,dp(22)));
        info.addView(v,new LinearLayout.LayoutParams(-1,dp(20)));
        row.addView(info,new LinearLayout.LayoutParams(0,-2,1));

        ImageButton star=new ImageButton(this);
        star.setImageResource(net.teamceleste.wiiulator.R.drawable.ic_star);
        star.setColorFilter(favorites.contains(g.name)?PRIMARY:MUTED);
        star.setBackgroundColor(Color.TRANSPARENT);
        star.setContentDescription("Favorite");
        star.setOnClickListener(view->{if(favorites.contains(g.name))favorites.remove(g.name);else favorites.add(g.name);showLibrary();});
        row.addView(star,new LinearLayout.LayoutParams(dp(48),dp(48)));
        outer.addView(row);

        MaterialButton play=button("Open game",net.teamceleste.wiiulator.R.drawable.ic_play);
        play.setOnClickListener(view->startActivity(new Intent(this,EmulatorActivity.class)));
        LinearLayout.LayoutParams pp=new LinearLayout.LayoutParams(-1,dp(48));
        pp.topMargin=dp(14);
        outer.addView(play,pp);
        c.addView(outer);

        LinearLayout.LayoutParams cp=new LinearLayout.LayoutParams(-1,-2);
        cp.bottomMargin=dp(12);
        content.addView(c,cp);
    }

    private void showFavorites() {
        resetContent();
        TextView title=text("Favorites",30,TEXT);
        title.setTypeface(Typeface.DEFAULT,Typeface.BOLD);
        content.addView(title,new LinearLayout.LayoutParams(-1,dp(48)));
        TextView sub=text("Games you marked for quick access.",14,MUTED);
        content.addView(sub,new LinearLayout.LayoutParams(-1,dp(30)));
        addGap(12);

        boolean any=false;
        for(Game g:games) if(favorites.contains(g.name)){ addGameCard(g); any=true; }
        if(!any) {
            MaterialCardView c=card();
            TextView t=text("No favorites yet",20,TEXT);
            t.setGravity(Gravity.CENTER);
            t.setTypeface(Typeface.DEFAULT,Typeface.BOLD);
            c.addView(t,new LinearLayout.LayoutParams(-1,dp(100)));
            content.addView(c);
        }
    }

    private void showSettings() {
        resetContent();
        TextView title=text("Settings",30,TEXT);
        title.setTypeface(Typeface.DEFAULT,Typeface.BOLD);
        content.addView(title,new LinearLayout.LayoutParams(-1,dp(48)));
        TextView sub=text("Configure emulation, controls, graphics and storage.",14,MUTED);
        content.addView(sub,new LinearLayout.LayoutParams(-1,dp(30)));

        section("EMULATION");
        setting("Graphics","Vulkan · Auto · 16:9",net.teamceleste.wiiulator.R.drawable.ic_library,v->showGraphics());
        setting("Controls","Wii U GamePad · Rumble",net.teamceleste.wiiulator.R.drawable.ic_gamepad,v->showControls());
        setting("Audio","Enabled · 100%",net.teamceleste.wiiulator.R.drawable.ic_settings,v->showAudio());
        setting("System","Memory · Performance",net.teamceleste.wiiulator.R.drawable.ic_settings,v->showSystem());

        section("SYSTEM");
        setting("Wii U System Update","Region and NUS metadata",net.teamceleste.wiiulator.R.drawable.ic_settings,v->showUpdate());
        setting("Games Folder","Documents / games",net.teamceleste.wiiulator.R.drawable.ic_library,v->showStorage());

        section("DEVELOPER");
        setting("Debugging","Overlay and logging",net.teamceleste.wiiulator.R.drawable.ic_settings,v->showDebug());

        section("ABOUT");
        setting("About WiiUlator","Version 1.0 · Android",net.teamceleste.wiiulator.R.drawable.ic_star,v->showAbout());
    }

    private void setting(String title,String sub,int icon,View.OnClickListener click) {
        MaterialCardView c=card();
        LinearLayout r=new LinearLayout(this);
        r.setGravity(Gravity.CENTER_VERTICAL);
        r.setPadding(dp(12),dp(8),dp(8),dp(8));
        ImageView i=new ImageView(this);
        i.setImageResource(icon);
        i.setColorFilter(PRIMARY);
        r.addView(i,new LinearLayout.LayoutParams(dp(44),dp(44)));
        LinearLayout info=new LinearLayout(this);
        info.setOrientation(LinearLayout.VERTICAL);
        info.setPadding(dp(8),0,dp(8),0);
        TextView a=text(title,16,TEXT); a.setTypeface(Typeface.DEFAULT,Typeface.BOLD);
        TextView b=text(sub,13,MUTED);
        info.addView(a,new LinearLayout.LayoutParams(-1,dp(25)));
        info.addView(b,new LinearLayout.LayoutParams(-1,dp(22)));
        r.addView(info,new LinearLayout.LayoutParams(0,dp(54),1));
        TextView arrow=text("›",28,MUTED);arrow.setGravity(Gravity.CENTER);
        r.addView(arrow,new LinearLayout.LayoutParams(dp(28),dp(54)));
        c.addView(r);
        c.setOnClickListener(click);
        LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,dp(70));
        p.bottomMargin=dp(8);
        content.addView(c,p);
    }

    private void subHeader(String title) {
        resetContent();
        LinearLayout row=new LinearLayout(this);
        row.setGravity(Gravity.CENTER_VERTICAL);
        TextView back=text("‹",38,TEXT);back.setGravity(Gravity.CENTER);
        back.setOnClickListener(v->showSettings());
        row.addView(back,new LinearLayout.LayoutParams(dp(48),dp(48)));
        TextView t=text(title,25,TEXT);t.setTypeface(Typeface.DEFAULT,Typeface.BOLD);
        row.addView(t,new LinearLayout.LayoutParams(0,dp(48),1));
        content.addView(row);
    }

    private void rowLabel(String title,String value) {
        MaterialCardView c=card();
        LinearLayout r=new LinearLayout(this);r.setGravity(Gravity.CENTER_VERTICAL);r.setPadding(dp(16),0,dp(16),0);
        TextView a=text(title,15,TEXT);
        TextView b=text(value,14,MUTED);b.setGravity(Gravity.RIGHT);
        r.addView(a,new LinearLayout.LayoutParams(0,dp(56),1));
        r.addView(b,new LinearLayout.LayoutParams(dp(150),dp(56)));
        c.addView(r);
        LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,dp(58));p.bottomMargin=dp(7);content.addView(c,p);
    }

    private void addSwitch(String title,boolean def,String key) {
        MaterialCardView c=card();
        LinearLayout r=new LinearLayout(this);r.setGravity(Gravity.CENTER_VERTICAL);r.setPadding(dp(16),0,dp(8),0);
        TextView t=text(title,15,TEXT);
        MaterialSwitch sw=new MaterialSwitch(this);
        sw.setChecked(prefs.getBoolean(key,def));
        sw.setOnCheckedChangeListener((b,v)->prefs.edit().putBoolean(key,v).apply());
        r.addView(t,new LinearLayout.LayoutParams(0,dp(58),1));
        r.addView(sw,new LinearLayout.LayoutParams(dp(64),dp(58)));
        c.addView(r);
        content.addView(c,new LinearLayout.LayoutParams(-1,dp(64)));
    }

    private void addSpinner(String title,String[] values,String key,String def) {
        MaterialCardView c=card();
        LinearLayout box=new LinearLayout(this);box.setOrientation(LinearLayout.VERTICAL);box.setPadding(dp(16),dp(10),dp(16),dp(8));
        TextView t=text(title,13,MUTED);box.addView(t,new LinearLayout.LayoutParams(-1,dp(25)));
        Spinner sp=new Spinner(this);
        ArrayAdapter<String> ad=new ArrayAdapter<>(this,android.R.layout.simple_spinner_dropdown_item,values);
        sp.setAdapter(ad);
        int idx=Arrays.asList(values).indexOf(prefs.getString(key,def));
        if(idx>=0)sp.setSelection(idx);
        sp.setOnItemSelectedListener(new android.widget.AdapterView.OnItemSelectedListener(){
            public void onNothingSelected(android.widget.AdapterView<?> p){}
            public void onItemSelected(android.widget.AdapterView<?> p,View v,int pos,long id){prefs.edit().putString(key,values[pos]).apply();}
        });
        box.addView(sp,new LinearLayout.LayoutParams(-1,dp(48)));
        c.addView(box);
        LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,-2);p.bottomMargin=dp(8);content.addView(c,p);
    }

    private void showGraphics() {
        subHeader("Graphics");
        section("RENDERER");
        addSpinner("Graphics backend",new String[]{"Vulkan","OpenGL ES (Compatibility)"},"graphicsBackend","Vulkan");
        addSpinner("Quality",new String[]{"Auto","Low","Medium","High"},"graphicsQuality","Auto");
        section("DISPLAY");
        addSpinner("Aspect ratio",new String[]{"16:9","4:3"},"displayAspectRatio","16:9");
        addSpinner("Resolution",new String[]{"Native","1280 × 720","1600 × 900","1920 × 1080","2560 × 1440"},"gameResolution","Native");
        addSwitch("Performance mode",false,"performanceMode");
    }

    private void showControls() {
        subHeader("Controls");
        section("CONTROLLER");
        addSpinner("Controller",new String[]{"Wii U GamePad","Pro Controller","Touch Controls"},"controllerType","Wii U GamePad");
        addSwitch("Rumble",true,"rumbleEnabled");
        section("BUTTON MAPPING");
        MaterialButton b=button("Configure controls",net.teamceleste.wiiulator.R.drawable.ic_gamepad);
        b.setOnClickListener(v->showControlLayout());
        content.addView(b,new LinearLayout.LayoutParams(-1,dp(50)));
    }

    private void showControlLayout() {
        subHeader("Configure controls");
        section("MAPPING");
        rowLabel("A","A");rowLabel("B","B");rowLabel("X","X");rowLabel("Y","Y");rowLabel("D-Pad","D-Pad");
    }

    private void showAudio() {
        subHeader("Audio");
        section("GAME AUDIO");
        addSwitch("Enable audio",true,"audioEnabled");
        rowLabel("Volume",Math.round(prefs.getFloat("audioVolume",1f)*100)+"%");
        MaterialButton mute=button("Set volume to 100%",net.teamceleste.wiiulator.R.drawable.ic_settings);
        mute.setOnClickListener(v->{prefs.edit().putFloat("audioVolume",1f).apply();showAudio();});
        content.addView(mute,new LinearLayout.LayoutParams(-1,dp(50)));
    }

    private void showSystem() {
        subHeader("System");
        section("GENERAL");
        addSwitch("Auto save",true,"autoSave");
        addSwitch("Confirm before exit",true,"confirmExit");
        section("MEMORY");
        rowLabel("Maximum RAM","512 MB");
        rowLabel("Architecture","ARM64");
        section("PERFORMANCE");
        rowLabel("Graphics","Vulkan");
        rowLabel("Minimum Android","Android 8.0");
        rowLabel("JIT","Available");
    }

    private void showUpdate() {
        subHeader("Wii U System Update");
        section("REGION");
        addSpinner("Region",new String[]{"USA","EUR","JPN"},"updateRegion","USA");
        section("NUS");
        rowLabel("Source","Nintendo Wii U NUS");
        rowLabel("Status","Not checked");
        MaterialButton b=button("Check for updates",net.teamceleste.wiiulator.R.drawable.ic_settings);
        b.setOnClickListener(v->Toast.makeText(this,"Update metadata check will use the Wii U NUS service.",Toast.LENGTH_LONG).show());
        content.addView(b,new LinearLayout.LayoutParams(-1,dp(50)));
    }

    private void showDebug() {
        subHeader("Debugging");
        section("TOOLS");
        addSwitch("Performance overlay",false,"debugOverlayEnabled");
        addSwitch("Debug logging",false,"debugLoggingEnabled");
        section("RUNTIME");
        rowLabel("Renderer","Vulkan");
        rowLabel("CPU","ARM64");
        rowLabel("Emulation speed","100%");
    }

    private void showStorage() {
        subHeader("Games Folder");
        section("STORAGE");
        rowLabel("Folder","games");
        rowLabel("Path","Documents/games");
        TextView n=text("Imported games stay inside WiiUlator's app storage. Game files are not bundled.",13,MUTED);
        n.setPadding(dp(8),dp(12),dp(8),dp(12));
        content.addView(n);
    }

    private void showAbout() {
        subHeader("About WiiUlator");
        section("APP");
        rowLabel("Version","1.0");
        rowLabel("Build","26W002");
        rowLabel("Platform","Android");
        MaterialCardView c=card();
        LinearLayout box=new LinearLayout(this);box.setOrientation(LinearLayout.VERTICAL);box.setGravity(Gravity.CENTER);box.setPadding(dp(20),dp(24),dp(20),dp(24));
        TextView n=text("WiiUlator",25,TEXT);n.setGravity(Gravity.CENTER);n.setTypeface(Typeface.DEFAULT,Typeface.BOLD);
        TextView s=text("Made by Team Celeste",14,MUTED);s.setGravity(Gravity.CENTER);
        box.addView(n,new LinearLayout.LayoutParams(-1,dp(42)));box.addView(s,new LinearLayout.LayoutParams(-1,dp(30)));
        c.addView(box);content.addView(c);
    }

    private void openPicker() {
        Intent i=new Intent(Intent.ACTION_OPEN_DOCUMENT);
        i.setType("*/*");
        i.putExtra(Intent.EXTRA_MIME_TYPES,new String[]{"application/zip","application/octet-stream"});
        i.addCategory(Intent.CATEGORY_OPENABLE);
        startActivityForResult(i,PICK);
    }

    @Override protected void onActivityResult(int r,int c,Intent d) {
        super.onActivityResult(r,c,d);
        if(r!=PICK||c!=RESULT_OK||d==null)return;
        Uri uri=d.getData();if(uri==null)return;
        try(InputStream in=getContentResolver().openInputStream(uri)) {
            byte[] data=readAll(in);
            new EmulatorCore().loadElf(data);
            String name=uri.getLastPathSegment();
            if(name==null)name="Imported Wii U Game";
            games.add(new Game(name,"Local","Ready"));
            showLibrary();
        } catch(Exception e) {
            Toast.makeText(this,"Load failed: "+e.getMessage(),Toast.LENGTH_LONG).show();
        }
    }

    static byte[] readAll(InputStream in)throws IOException {
        ByteArrayOutputStream b=new ByteArrayOutputStream();
        byte[] x=new byte[65536];int n;
        while((n=in.read(x))>0)b.write(x,0,n);
        return b.toByteArray();
    }
}
