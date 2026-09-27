package net.teamceleste.wiiulator;

import android.app.*;
import android.os.*;
import android.content.*;
import android.graphics.Color;
import android.graphics.Typeface;
import android.view.*;
import android.widget.*;
import java.io.*;
import java.util.*;

public final class MainActivity extends Activity {
    private final EmulatorCore core = new EmulatorCore();
    private TextView status;
    private LinearLayout content;
    private int selectedTab = 0;
    private final ArrayList<Game> games = new ArrayList<>();
    private final HashSet<String> favorites = new HashSet<>();
    private static final int PICK = 7;

    private static final class Game {
        final String name, provider, version;
        Game(String n, String p, String v) { name=n; provider=p; version=v; }
    }

    @Override public void onCreate(Bundle b) {
        super.onCreate(b);
        getWindow().setNavigationBarColor(Color.BLACK);
        getWindow().setStatusBarColor(Color.BLACK);
        buildShell();
        showLibrary();
    }

    private TextView text(String value, float size, int color) {
        TextView t = new TextView(this);
        t.setText(value); t.setTextSize(size); t.setTextColor(color);
        return t;
    }

    private void buildShell() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(Color.BLACK);

        FrameLayout main = new FrameLayout(this);
        content = new LinearLayout(this);
        content.setOrientation(LinearLayout.VERTICAL);
        main.addView(content, new FrameLayout.LayoutParams(-1,-1));
        root.addView(main, new LinearLayout.LayoutParams(-1,0,1));

        LinearLayout tabs = new LinearLayout(this);
        tabs.setOrientation(LinearLayout.HORIZONTAL);
        tabs.setPadding(8,8,8,8);
        tabs.setBackgroundColor(Color.rgb(20,20,20));

        String[] labels = {"Library","Favorites","Settings"};
        for (int i=0;i<labels.length;i++) {
            final int tab=i;
            Button b = new Button(this);
            b.setText(labels[i]);
            b.setTextSize(12);
            b.setAllCaps(false);
            b.setTextColor(Color.WHITE);
            b.setOnClickListener(v -> {
                selectedTab=tab;
                if(tab==0) showLibrary();
                else if(tab==1) showFavorites();
                else showSettings();
            });
            tabs.addView(b,new LinearLayout.LayoutParams(0,-2,1));
        }
        root.addView(tabs);
        setContentView(root);
    }

    private void basePage(String title, String subtitle) {
        content.removeAllViews();
        content.setPadding(20,20,20,20);
        TextView h=text(title,30,Color.WHITE);
        h.setTypeface(Typeface.DEFAULT,Typeface.BOLD);
        content.addView(h);
        if (subtitle != null) {
            TextView s=text(subtitle,14,Color.LTGRAY);
            s.setPadding(0,4,0,16);
            content.addView(s);
        }
    }

    private void showLibrary() {
        basePage("Library", "Your Wii U games");
        LinearLayout actions=new LinearLayout(this);
        actions.setOrientation(LinearLayout.HORIZONTAL);
        Button importButton=new Button(this);
        importButton.setText("＋ Import Game");
        importButton.setAllCaps(false);
        importButton.setOnClickListener(v -> openPicker());
        actions.addView(importButton,new LinearLayout.LayoutParams(-1,-2));
        content.addView(actions);

        status=text(games.isEmpty() ? "No Games\nImport Wii U homebrew to get started." : "",15,Color.LTGRAY);
        status.setGravity(Gravity.CENTER);
        content.addView(status,new LinearLayout.LayoutParams(-1,0,1));

        if (!games.isEmpty()) {
            content.removeView(status);
            LinearLayout list=new LinearLayout(this);
            list.setOrientation(LinearLayout.VERTICAL);
            for(Game g:games) addGameRow(list,g);
            ScrollView scroll=new ScrollView(this);
            scroll.addView(list);
            content.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
        }
    }

    private void addGameRow(LinearLayout list, Game g) {
        LinearLayout row=new LinearLayout(this);
        row.setGravity(Gravity.CENTER_VERTICAL);
        row.setPadding(8,14,8,14);
        TextView info=text(g.name+"\nProvider: "+g.provider+"\nVersion: "+g.version,16,Color.WHITE);
        row.addView(info,new LinearLayout.LayoutParams(0,-2,1));
        Button star=new Button(this);
        star.setText(favorites.contains(g.name) ? "★" : "☆");
        star.setTextSize(24);
        star.setAllCaps(false);
        star.setOnClickListener(v->{ if(favorites.contains(g.name))favorites.remove(g.name);else favorites.add(g.name); showLibrary();});
        row.addView(star,new LinearLayout.LayoutParams(64,-2));
        list.addView(row);
    }

    private void showFavorites() {
        basePage("Favorites", "Your starred games");
        if(favorites.isEmpty()) {
            TextView empty=text("☆\n\nNo Favorites\nFavorite games will appear here.",16,Color.LTGRAY);
            empty.setGravity(Gravity.CENTER);
            content.addView(empty,new LinearLayout.LayoutParams(-1,0,1));
            return;
        }
        LinearLayout list=new LinearLayout(this);
        list.setOrientation(LinearLayout.VERTICAL);
        for(Game g:games) if(favorites.contains(g.name)) addGameRow(list,g);
        ScrollView scroll=new ScrollView(this); scroll.addView(list);
        content.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
    }

    private void showSettings() {
        basePage("Settings", "WiiUlator configuration");
        String[] sections={"Graphics","Controls","Audio","System","Storage","Debugging","About"};
        LinearLayout list=new LinearLayout(this);
        list.setOrientation(LinearLayout.VERTICAL);
        for(String s:sections) {
            Button b=new Button(this);
            b.setText(s+"   ›");
            b.setTextSize(16); b.setAllCaps(false); b.setGravity(Gravity.LEFT|Gravity.CENTER_VERTICAL);
            b.setTextColor(Color.WHITE);
            b.setOnClickListener(v -> showSettingDetail(s));
            list.addView(b,new LinearLayout.LayoutParams(-1,-2));
        }
        ScrollView scroll=new ScrollView(this); scroll.addView(list);
        content.addView(scroll,new LinearLayout.LayoutParams(-1,0,1));
    }

    private void showSettingDetail(String section) {
        basePage(section,null);
        TextView body;
        if(section.equals("About"))
            body=text("WiiUlator\n\nMade with ♥ by Team Celeste\n\nAndroid edition",18,Color.LTGRAY);
        else
            body=text(section+" settings\n\nConfiguration options for "+section+" will appear here.",17,Color.LTGRAY);
        body.setPadding(4,20,4,20);
        content.addView(body,new LinearLayout.LayoutParams(-1,-2));
        Button back=new Button(this); back.setText("‹ Back"); back.setAllCaps(false);
        back.setOnClickListener(v->showSettings()); content.addView(back);
    }

    private void openPicker() {
        Intent i=new Intent(Intent.ACTION_OPEN_DOCUMENT);
        i.setType("application/octet-stream");
        i.addCategory(Intent.CATEGORY_OPENABLE);
        startActivityForResult(i,PICK);
    }

    @Override protected void onActivityResult(int r,int c,Intent d) {
        super.onActivityResult(r,c,d);
        if(r!=PICK||c!=RESULT_OK||d==null)return;
        try(InputStream in=getContentResolver().openInputStream(d.getData())) {
            byte[] data=readAll(in);
            core.loadElf(data);
            games.add(new Game("Imported Wii U Game","Local","Unknown"));
            showLibrary();
        } catch(Exception e) {
            showLibrary();
            Toast.makeText(this,"Load failed: "+e.getMessage(),Toast.LENGTH_LONG).show();
        }
    }

    static byte[] readAll(InputStream in)throws IOException {
        ByteArrayOutputStream b=new ByteArrayOutputStream();
        byte[] x=new byte[65536]; int n;
        while((n=in.read(x))>0)b.write(x,0,n);
        return b.toByteArray();
    }
}
