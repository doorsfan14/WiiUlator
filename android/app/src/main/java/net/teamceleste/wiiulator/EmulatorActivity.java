package net.teamceleste.wiiulator;

import android.app.Activity;
import android.os.Bundle;
import android.content.pm.ActivityInfo;
import android.graphics.Color;
import android.view.View;
import android.widget.TextView;

public final class EmulatorActivity extends Activity {
    @Override public void onCreate(Bundle b) {
        super.onCreate(b);
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE);
        getWindow().setFlags(1024,1024);
        TextView screen=new TextView(this);
        screen.setBackgroundColor(Color.BLACK);
        screen.setTextColor(Color.WHITE);
        screen.setGravity(17);
        screen.setTextSize(16);
        screen.setText("WiiUlator\n\nEmulation core");
        setContentView(screen);
    }
    @Override protected void onDestroy() {
        setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED);
        super.onDestroy();
    }
}