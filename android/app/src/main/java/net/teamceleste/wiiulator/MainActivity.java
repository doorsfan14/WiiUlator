package net.teamceleste.wiiulator;

import android.app.*;
import android.os.*;
import android.content.*;
import android.graphics.*;
import android.graphics.drawable.*;
import android.net.Uri;
import android.view.*;
import android.widget.*;
import java.io.*;
import java.util.*;

public final class MainActivity extends Activity {
    private final EmulatorCore core = new EmulatorCore();
    private LinearLayout page, content;
    private int selectedTab = 0;
    private final ArrayList<Game> games = new ArrayList<>();
    private final HashSet<String> favorites = new HashSet<>();
    private android.content.SharedPreferences prefs;
    private static final int PICK = 7;

    private static final int BG = Color.rgb(7, 12, 20);
    private static final int PANEL = Color.rgb(15, 24, 36);
    private static final int PANEL2 = Color.rgb(20, 32, 48);
    private static final int BLUE = Color.rgb(0, 174, 255);
    private static final int CYAN = Color.rgb(85, 220, 255);
    private static final int TEXT = Color.rgb(245, 249, 255);
    private static final int MUTED = Color.rgb(150, 166, 184);

    private static final class Game {
        final String name, provider, version;
        Game(String n, String p, String v) { name=n; provider=p; version=v; }
    }

    @Override public void onCreate(Bundle b) {
        super.onCreate(b);
        prefs = getSharedPreferences("wiiulator", MODE_PRIVATE);
        getWindow().setStatusBarColor(BG);
        getWindow().setNavigationBarColor(Color.BLACK);
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR & ~View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR);
        buildShell();
        showLibrary();
    }

    private GradientDrawable bg(int color, float radius) {
        GradientDrawable d = new GradientDrawable();
        d.setColor(color);
        d.setCornerRadius(radius);
        return d;
    }

    private GradientDrawable gradient(float radius) {
        GradientDrawable d = new GradientDrawable(
            GradientDrawable.Orientation.TL_BR,
            new int[]{Color.rgb(0, 119, 190), Color.rgb(0, 205, 255)}
        );
        d.setCornerRadius(radius);
        return d;
    }

    private TextView text(String value, float size, int color) {
        TextView t = new TextView(this);
        t.setText(value);
        t.setTextSize(size);
        t.setTextColor(color);
        t.setGravity(Gravity.CENTER_VERTICAL);
        return t;
    }

    private int dp(int v) { return (int)(v * getResources().getDisplayMetrics().density + .5f); }

    private LinearLayout lpRow() {
        LinearLayout l = new LinearLayout(this);
        l.setOrientation(LinearLayout.HORIZONTAL);
        l.setGravity(Gravity.CENTER_VERTICAL);
        return l;
    }

    private void buildShell() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(BG);

        FrameLayout frame = new FrameLayout(this);
        page = new LinearLayout(this);
        page.setOrientation(LinearLayout.VERTICAL);
        page.setBackgroundColor(BG);
        frame.addView(page, new FrameLayout.LayoutParams(-1,-1));
        root.addView(frame, new LinearLayout.LayoutParams(-1,0,1));

        LinearLayout nav = new LinearLayout(this);
        nav.setOrientation(LinearLayout.HORIZONTAL);
        nav.setGravity(Gravity.CENTER);
        nav.setPadding(dp(10),dp(8),dp(10),dp(10));
        nav.setBackgroundColor(Color.rgb(11,18,28));

        String[] labels = {"Library","Favorites","Settings"};
        String[] glyphs = {"▦","★","⚙"};
        for(int i=0;i<3;i++){
            final int tab=i;
            LinearLayout item=lpRow();
            item.setOrientation(LinearLayout.VERTICAL);
            item.setGravity(Gravity.CENTER);
            TextView icon=text(glyphs[i],20,TEXT);
            icon.setGravity(Gravity.CENTER);
            TextView label=text(labels[i],11,MUTED);
            label.setGravity(Gravity.CENTER);
            item.addView(icon,new LinearLayout.LayoutParams(-1,dp(25)));
            item.addView(label,new LinearLayout.LayoutParams(-1,dp(20)));
            item.setPadding(dp(4),0,dp(4),0);
            item.setOnClickListener(v->{selectedTab=tab;if(tab==0)showLibrary();else if(tab==1)showFavorites();else showSettings();});
            nav.addView(item,new LinearLayout.LayoutParams(0,dp(55),1));
        }
        root.addView(nav,new LinearLayout.LayoutParams(-1,dp(73)));
        setContentView(root);
    }

    private void header(String title,String subtitle) {
        page.removeAllViews();
        LinearLayout h=new LinearLayout(this);
        h.setOrientation(LinearLayout.VERTICAL);
        h.setPadding(dp(22),dp(24),dp(22),dp(12));
        TextView t=text(title,32,TEXT); t.setTypeface(Typeface.DEFAULT,Typeface.BOLD);
        h.addView(t,new LinearLayout.LayoutParams(-1,dp(42)));
        if(subtitle!=null){TextView s=text(subtitle,14,MUTED);h.addView(s,new LinearLayout.LayoutParams(-1,dp(26)));}
        page.addView(h);
        content=new LinearLayout(this); content.setOrientation(LinearLayout.VERTICAL);
        content.setPadding(dp(16),0,dp(16),dp(18));
        ScrollView scroll=new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.addView(content);
        page.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
    }

    private TextView pill(String value) {
        TextView v=text(value,11,CYAN);
        v.setGravity(Gravity.CENTER);
        v.setPadding(dp(10),0,dp(10),0);
        v.setBackground(bg(Color.rgb(8,54,78),dp(30)));
        return v;
    }

    private LinearLayout card() {
        LinearLayout c=new LinearLayout(this);
        c.setOrientation(LinearLayout.VERTICAL);
        c.setPadding(dp(16),dp(14),dp(16),dp(14));
        c.setBackground(bg(PANEL,dp(18)));
        return c;
    }

    private void addSpace(int h){Space s=new Space(this);content.addView(s,new LinearLayout.LayoutParams(1,dp(h)));}

    private void showLibrary() {
        header("Library","Your Wii U games");
        LinearLayout top=lpRow();
        TextView count=pill(games.size()+" GAMES");
        top.addView(count,new LinearLayout.LayoutParams(dp(95),dp(30)));
        Space sp=new Space(this);top.addView(sp,new LinearLayout.LayoutParams(0,1,1));
        Button add=new Button(this);add.setText("+");add.setTextSize(24);add.setTextColor(TEXT);add.setAllCaps(false);
        add.setBackground(gradient(dp(16)));add.setOnClickListener(v->openPicker());
        top.addView(add,new LinearLayout.LayoutParams(dp(54),dp(48)));
        content.addView(top);
        addSpace(14);

        if(games.isEmpty()){
            LinearLayout empty=card();empty.setGravity(Gravity.CENTER);
            TextView ico=text("▦",52,CYAN);ico.setGravity(Gravity.CENTER);
            empty.addView(ico,new LinearLayout.LayoutParams(-1,dp(70)));
            TextView title=text("No Games",22,TEXT);title.setGravity(Gravity.CENTER);
            empty.addView(title);
            TextView sub=text("Import a Wii U game or homebrew executable to get started.",14,MUTED);sub.setGravity(Gravity.CENTER);sub.setPadding(dp(25),dp(8),dp(25),dp(20));
            empty.addView(sub);
            Button imp=primaryButton("IMPORT GAME");imp.setOnClickListener(v->openPicker());empty.addView(imp,new LinearLayout.LayoutParams(-1,dp(48)));
            content.addView(empty,new LinearLayout.LayoutParams(-1,-2));
            return;
        }

        for(Game g:games)addGameCard(g);
    }

    private Button primaryButton(String label){
        Button b=new Button(this);b.setText(label);b.setTextSize(12);b.setTextColor(Color.WHITE);b.setAllCaps(false);
        b.setTypeface(Typeface.DEFAULT,Typeface.BOLD);b.setBackground(gradient(dp(14)));return b;
    }

    private void addGameCard(Game g){
        LinearLayout c=card();
        LinearLayout row=lpRow();
        TextView icon=text("Wii U",13,Color.WHITE);icon.setGravity(Gravity.CENTER);icon.setTypeface(Typeface.DEFAULT,Typeface.BOLD);icon.setBackground(gradient(dp(14)));
        row.addView(icon,new LinearLayout.LayoutParams(dp(72),dp(72)));
        LinearLayout info=new LinearLayout(this);info.setOrientation(LinearLayout.VERTICAL);info.setPadding(dp(14),0,dp(8),0);
        TextView n=text(g.name,18,TEXT);n.setTypeface(Typeface.DEFAULT,Typeface.BOLD);
        TextView p=text(g.provider,13,MUTED);
        TextView v=text(g.version.isEmpty()?"Ready":g.version,12,CYAN);
        info.addView(n,new LinearLayout.LayoutParams(-1,dp(28)));info.addView(p,new LinearLayout.LayoutParams(-1,dp(22)));info.addView(v,new LinearLayout.LayoutParams(-1,dp(20)));
        row.addView(info,new LinearLayout.LayoutParams(0,-2,1));
        Button star=new Button(this);star.setText(favorites.contains(g.name)?"★":"☆");star.setTextSize(24);star.setTextColor(favorites.contains(g.name)?Color.rgb(255,205,65):MUTED);star.setAllCaps(false);star.setBackgroundColor(Color.TRANSPARENT);
        star.setOnClickListener(view->{if(favorites.contains(g.name))favorites.remove(g.name);else favorites.add(g.name);showLibrary();});
        row.addView(star,new LinearLayout.LayoutParams(dp(50),dp(58)));
        c.addView(row);
        Button play=primaryButton("OPEN GAME");play.setOnClickListener(view->Toast.makeText(this,"Game launch will use the emulator core.",Toast.LENGTH_SHORT).show());
        LinearLayout.LayoutParams pp=new LinearLayout.LayoutParams(-1,dp(42));pp.topMargin=dp(12);c.addView(play,pp);
        LinearLayout.LayoutParams cp=new LinearLayout.LayoutParams(-1,-2);cp.bottomMargin=dp(12);content.addView(c,cp);
    }

    private void showFavorites(){
        header("Favorites","Your starred games");
        if(favorites.isEmpty()){
            LinearLayout empty=card();empty.setGravity(Gravity.CENTER);
            TextView i=text("★",48,MUTED);i.setGravity(Gravity.CENTER);empty.addView(i,new LinearLayout.LayoutParams(-1,dp(65)));
            TextView t=text("No Favorites",20,TEXT);t.setGravity(Gravity.CENTER);empty.addView(t);
            TextView s=text("Star games from your Library to keep them here.",14,MUTED);s.setGravity(Gravity.CENTER);s.setPadding(dp(20),dp(8),dp(20),dp(15));empty.addView(s);
            content.addView(empty);
            return;
        }
        for(Game g:games)if(favorites.contains(g.name))addGameCard(g);
    }

    private void showSettings(){
        header("Settings","Tune WiiUlator to your device");
        settingGroup("LANGUAGE");
        settingRow("Language","System Language","▤",v->showLanguage());
        settingGroup("EMULATION");
        settingRow("Graphics","Metal · Auto · 16:9","▣",v->showGraphics());
        settingRow("Controls","Wii U GamePad · Rumble","◉",v->showControls());
        settingRow("Audio","Enabled · 100%","♫",v->showAudio());
        settingRow("System","Memory · JIT · Performance","⚙",v->showSystem());
        settingRow("System Update","Nintendo Wii U NUS","↓",v->showUpdate());
        settingGroup("DEVELOPER");
        settingRow("Debugging","Overlay · Logging","◇",v->showDebug());
        settingGroup("STORAGE");
        settingRow("Games Folder","Documents / games","□",v->showStorage());
        settingGroup("ABOUT");
        settingRow("About","WiiUlator 1.0 · 26W002","i",v->showAbout());
    }

    private void settingGroup(String title){
        TextView g=text(title,11,CYAN);g.setTypeface(Typeface.DEFAULT,Typeface.BOLD);g.setPadding(dp(8),dp(16),dp(8),dp(7));content.addView(g,new LinearLayout.LayoutParams(-1,dp(36)));
    }

    private void settingRow(String title,String sub,String glyph,View.OnClickListener click){
        LinearLayout r=lpRow();r.setPadding(dp(14),dp(8),dp(10),dp(8));r.setBackground(bg(PANEL,dp(16)));
        TextView ic=text(glyph,20,CYAN);ic.setGravity(Gravity.CENTER);
        r.addView(ic,new LinearLayout.LayoutParams(dp(42),dp(46)));
        LinearLayout info=new LinearLayout(this);info.setOrientation(LinearLayout.VERTICAL);
        TextView t=text(title,16,TEXT);t.setTypeface(Typeface.DEFAULT,Typeface.BOLD);
        TextView s=text(sub,12,MUTED);info.addView(t,new LinearLayout.LayoutParams(-1,dp(25)));info.addView(s,new LinearLayout.LayoutParams(-1,dp(20)));
        r.addView(info,new LinearLayout.LayoutParams(0,dp(50),1));
        TextView arrow=text("›",28,MUTED);arrow.setGravity(Gravity.CENTER);r.addView(arrow,new LinearLayout.LayoutParams(dp(28),dp(50)));
        r.setOnClickListener(click);
        LinearLayout.LayoutParams rp=new LinearLayout.LayoutParams(-1,dp(66));rp.bottomMargin=dp(7);content.addView(r,rp);
    }

    private void subHeader(String title){
        page.removeAllViews();
        LinearLayout bar=lpRow();bar.setPadding(dp(14),dp(15),dp(18),dp(10));
        Button back=new Button(this);back.setText("‹");back.setTextSize(30);back.setTextColor(TEXT);back.setAllCaps(false);back.setBackgroundColor(Color.TRANSPARENT);back.setOnClickListener(v->showSettings());
        bar.addView(back,new LinearLayout.LayoutParams(dp(48),dp(48)));
        TextView t=text(title,25,TEXT);t.setTypeface(Typeface.DEFAULT,Typeface.BOLD);bar.addView(t,new LinearLayout.LayoutParams(0,dp(48),1));
        page.addView(bar);
        content=new LinearLayout(this);content.setOrientation(LinearLayout.VERTICAL);content.setPadding(dp(16),0,dp(16),dp(24));
        ScrollView scroll=new ScrollView(this);scroll.addView(content);page.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
    }

    private TextView sectionTitle(String s){TextView t=text(s,12,CYAN);t.setTypeface(Typeface.DEFAULT,Typeface.BOLD);t.setPadding(dp(4),dp(17),dp(4),dp(8));content.addView(t);return t;}

    private void rowLabel(String title,String value){
        LinearLayout r=lpRow();r.setPadding(dp(14),dp(11),dp(14),dp(11));r.setBackground(bg(PANEL,dp(14)));
        TextView a=text(title,15,TEXT);TextView b=text(value,14,MUTED);b.setGravity(Gravity.RIGHT);
        r.addView(a,new LinearLayout.LayoutParams(0,dp(42),1));r.addView(b,new LinearLayout.LayoutParams(dp(135),dp(42)));
        LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,dp(64));p.bottomMargin=dp(6);content.addView(r,p);
    }

    private void addSwitch(String title,boolean value,String key){
        LinearLayout r=lpRow();r.setPadding(dp(14),dp(7),dp(8),dp(7));r.setBackground(bg(PANEL,dp(14)));
        TextView t=text(title,15,TEXT);Switch sw=new Switch(this);sw.setChecked(prefs.getBoolean(key,value));sw.setOnCheckedChangeListener((b,c)->prefs.edit().putBoolean(key,c).apply());
        r.addView(t,new LinearLayout.LayoutParams(0,dp(50),1));r.addView(sw,new LinearLayout.LayoutParams(dp(60),dp(50)));
        LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,dp(64));p.bottomMargin=dp(6);content.addView(r,p);
    }

    private void addSpinner(String title,String[] values,String key,String def){
        LinearLayout box=card();TextView t=text(title,14,TEXT);t.setTypeface(Typeface.DEFAULT,Typeface.BOLD);box.addView(t);
        Spinner sp=new Spinner(this);ArrayAdapter<String> ad=new ArrayAdapter<String>(this,android.R.layout.simple_spinner_dropdown_item,values);
        sp.setAdapter(ad);String saved=prefs.getString(key,def);int idx=Arrays.asList(values).indexOf(saved);if(idx>=0)sp.setSelection(idx);
        sp.setOnItemSelectedListener(new android.widget.AdapterView.OnItemSelectedListener(){public void onNothingSelected(android.widget.AdapterView<?> p){}public void onItemSelected(android.widget.AdapterView<?> p,View v,int pos,long id){prefs.edit().putString(key,values[pos]).apply();}});
        box.addView(sp,new LinearLayout.LayoutParams(-1,dp(50)));
        LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,-2);p.bottomMargin=dp(8);content.addView(box,p);
    }

    private void showLanguage(){subHeader("Language");sectionTitle("LANGUAGE");addSpinner("Language",new String[]{"System Language","Spanish","Portuguese","Japanese","Chinese","English (UK)"},"language","System Language");}

    private void showGraphics(){
        subHeader("Graphics");
        sectionTitle("GRAPHICS BACKEND");addSpinner("Backend",new String[]{"Metal","Vulkan (Experimental)"},"graphicsBackend","Metal");
        sectionTitle("DISPLAY");addSpinner("Aspect Ratio",new String[]{"16:9","4:3"},"displayAspectRatio","16:9");
        sectionTitle("GAME RESOLUTION");addSpinner("Resolution",new String[]{"Native","1280 × 720","1600 × 900","1920 × 1080","2560 × 1440"},"gameResolution","Native");
        sectionTitle("RENDERING");addSpinner("Quality",new String[]{"Auto","Low","Medium","High"},"graphicsQuality","Auto");
        addSwitch("Performance Mode",false,"performanceMode");
        addSwitch("30 FPS = Full Emulation Speed",true,"thirtyFPSFullSpeed");
        TextView note=text("Metal is the primary graphics backend. Vulkan is experimental.",12,MUTED);note.setPadding(dp(8),dp(10),dp(8),dp(10));content.addView(note);
    }

    private void showControls(){
        subHeader("Controls");sectionTitle("CONTROLLER");
        addSpinner("Controller",new String[]{"Wii U GamePad","Pro Controller","Touch Controls"},"controllerType","Wii U GamePad");
        addSwitch("Rumble",true,"rumbleEnabled");
        sectionTitle("LAYOUT");
        Button b=primaryButton("CONFIGURE CONTROLS");b.setOnClickListener(v->showControlLayout());content.addView(b,new LinearLayout.LayoutParams(-1,dp(48)));
    }

    private void showControlLayout(){
        subHeader("Configure Controls");sectionTitle("BUTTONS");
        rowLabel("A","A");rowLabel("B","B");rowLabel("X","X");rowLabel("Y","Y");rowLabel("D-Pad","D-Pad");
        TextView n=text("Custom button mapping will be available as the emulator input system is implemented.",12,MUTED);n.setPadding(dp(8),dp(12),dp(8),dp(12));content.addView(n);
    }

    private void showAudio(){
        subHeader("Audio");sectionTitle("GAME AUDIO");addSwitch("Enable Audio",true,"audioEnabled");
        LinearLayout box=card();TextView t=text("Volume",15,TEXT);box.addView(t);
        SeekBar s=new SeekBar(this);s.setMax(100);s.setProgress((int)(prefs.getFloat("audioVolume",1f)*100));s.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener(){public void onProgressChanged(SeekBar b,int p,boolean f){prefs.edit().putFloat("audioVolume",p/100f).apply();}public void onStartTrackingTouch(SeekBar b){}public void onStopTrackingTouch(SeekBar b){}});
        box.addView(s,new LinearLayout.LayoutParams(-1,dp(45)));content.addView(box,new LinearLayout.LayoutParams(-1,-2));
        TextView n=text("Audio settings apply to emulated games. WiiUlator does not use interface sound effects.",12,MUTED);n.setPadding(dp(8),dp(12),dp(8),dp(12));content.addView(n);
    }

    private void showSystem(){
        subHeader("System");sectionTitle("SYSTEM");addSwitch("Auto Save",true,"autoSave");addSwitch("Confirm Before Exit",true,"confirmExit");
        sectionTitle("MEMORY");int ram=prefs.getInt("maximumRAMMB",512);rowLabel("Maximum RAM",ram+" MB");rowLabel("Recommended","512 MB");
        TextView jit=text("JIT     "+(Build.VERSION.SDK_INT>=24?"Available":"Unavailable"),15,TEXT);jit.setPadding(dp(14),dp(15),dp(14),dp(15));jit.setBackground(bg(PANEL,dp(14)));content.addView(jit);
        sectionTitle("PERFORMANCE");rowLabel("Architecture","ARM64");rowLabel("Graphics","Vulkan / Android");rowLabel("Minimum Android","Android 8.0");
    }

    private void showUpdate(){
        subHeader("System Update");sectionTitle("WII U REGION");addSpinner("Region",new String[]{"USA","EUR","JPN"},"updateRegion","USA");
        sectionTitle("NINTENDO UPDATE SERVICE");Button check=primaryButton("CHECK FOR UPDATES");check.setOnClickListener(v->Toast.makeText(this,"Update metadata check will use the Wii U NUS service.",Toast.LENGTH_LONG).show());content.addView(check,new LinearLayout.LayoutParams(-1,dp(48)));
        rowLabel("Source","Nintendo Wii U NUS");rowLabel("Build","26W002");sectionTitle("STATUS");rowLabel("Result","Not checked");
        TextView n=text("Proprietary system software is not bundled with WiiUlator.",12,MUTED);n.setPadding(dp(8),dp(12),dp(8),dp(12));content.addView(n);
    }

    private void showDebug(){
        subHeader("Debugging");sectionTitle("DEVELOPER TOOLS");addSwitch("Performance Overlay",false,"debugOverlayEnabled");addSwitch("Debug Logging",false,"debugLoggingEnabled");
        sectionTitle("OVERLAY");rowLabel("Display FPS","Live");rowLabel("Emulation Speed","100%");rowLabel("Frame Time","Live");rowLabel("Renderer","Vulkan");rowLabel("CPU","ARM64");rowLabel("JIT Support","Available");
    }

    private void showStorage(){
        subHeader("Games Folder");sectionTitle("LOCATION");rowLabel("Folder","games");rowLabel("Path","Documents/games");
        TextView n=text("Imported games are stored in WiiUlator's app storage. Game files are not included with WiiUlator.",12,MUTED);n.setPadding(dp(8),dp(12),dp(8),dp(12));content.addView(n);
    }

    private void showAbout(){
        subHeader("About");sectionTitle("WIIULATOR");rowLabel("Version","1.0");rowLabel("Build Identifier","26W002");rowLabel("Platform","Android");
        LinearLayout brand=card();brand.setGravity(Gravity.CENTER);TextView icon=text("Wii U",18,Color.WHITE);icon.setGravity(Gravity.CENTER);icon.setTypeface(Typeface.DEFAULT,Typeface.BOLD);icon.setBackground(gradient(dp(18)));brand.addView(icon,new LinearLayout.LayoutParams(dp(100),dp(60)));
        TextView name=text("WiiUlator",25,TEXT);name.setGravity(Gravity.CENTER);name.setTypeface(Typeface.DEFAULT,Typeface.BOLD);brand.addView(name,new LinearLayout.LayoutParams(-1,dp(42)));
        TextView made=text("Made with ♥ by Team Celeste",13,MUTED);made.setGravity(Gravity.CENTER);brand.addView(made,new LinearLayout.LayoutParams(-1,dp(30)));
        content.addView(brand);
        sectionTitle("OPEN SOURCE");TextView n=text("WiiUlator is open source and developed by Team Celeste.",13,MUTED);n.setPadding(dp(8),dp(8),dp(8),dp(8));content.addView(n);
    }

    private void openPicker(){
        Intent i=new Intent(Intent.ACTION_OPEN_DOCUMENT);
        i.setType("*/*");i.putExtra(Intent.EXTRA_MIME_TYPES,new String[]{"application/zip","application/octet-stream"});
        i.addCategory(Intent.CATEGORY_OPENABLE);startActivityForResult(i,PICK);
    }

    @Override protected void onActivityResult(int r,int c,Intent d){
        super.onActivityResult(r,c,d);if(r!=PICK||c!=RESULT_OK||d==null)return;
        Uri uri=d.getData();if(uri==null)return;
        try(InputStream in=getContentResolver().openInputStream(uri)){
            byte[] data=readAll(in);core.loadElf(data);
            String name=uri.getLastPathSegment();if(name==null)name="Imported Wii U Game";
            games.add(new Game(name,"Local","Ready"));showLibrary();
        }catch(Exception e){Toast.makeText(this,"Load failed: "+e.getMessage(),Toast.LENGTH_LONG).show();}
    }

    static byte[] readAll(InputStream in)throws IOException{
        ByteArrayOutputStream b=new ByteArrayOutputStream();byte[] x=new byte[65536];int n;
        while((n=in.read(x))>0)b.write(x,0,n);return b.toByteArray();
    }
}
