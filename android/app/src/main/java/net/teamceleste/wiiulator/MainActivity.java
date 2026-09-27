package net.teamceleste.wiiulator;

import android.app.*;import android.os.*;import android.content.*;import android.graphics.Color;import android.view.*;import android.widget.*;import java.io.*;

public final class MainActivity extends Activity{
 EmulatorCore core=new EmulatorCore(); TextView status; Button run,step; static final int PICK=7;
 public void onCreate(Bundle b){super.onCreate(b);LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);root.setPadding(32,32,32,32);root.setBackgroundColor(Color.BLACK);
  TextView title=new TextView(this);title.setText("WiiUlator");title.setTextColor(Color.WHITE);title.setTextSize(30);root.addView(title);
  status=new TextView(this);status.setTextColor(Color.LTGRAY);status.setText("PowerPC core ready — no game loaded");root.addView(status,new LinearLayout.LayoutParams(-1,0,1));
  Button open=new Button(this);open.setText("Open Wii U ELF / RPX");open.setOnClickListener(v->{Intent i=new Intent(Intent.ACTION_OPEN_DOCUMENT);i.setType("application/octet-stream");i.addCategory(Intent.CATEGORY_OPENABLE);startActivityForResult(i,PICK);});root.addView(open);
  LinearLayout bar=new LinearLayout(this);bar.setOrientation(LinearLayout.HORIZONTAL);step=new Button(this);step.setText("Step");run=new Button(this);run.setText("Run 2000");bar.addView(step,new LinearLayout.LayoutParams(0,-2,1));bar.addView(run,new LinearLayout.LayoutParams(0,-2,1));root.addView(bar);
  step.setEnabled(false);run.setEnabled(false);step.setOnClickListener(v->{core.run(1);update();});run.setOnClickListener(v->{core.run(2000);update();});setContentView(root);
 }
 protected void onActivityResult(int r,int c,Intent d){super.onActivityResult(r,c,d);if(r!=PICK||c!=RESULT_OK||d==null)return;try(InputStream in=getContentResolver().openInputStream(d.getData())){byte[] data=readAll(in);core.loadElf(data);step.setEnabled(true);run.setEnabled(true);update();}catch(Exception e){status.setText("Load failed: "+e.getMessage());}}
 void update(){status.setText(String.format("Loaded\nPC 0x%08X\nInstructions %,d\nLast 0x%08X%s",core.cpu.pc,core.instructions,core.cpu.last,core.cpu.unsupported!=0?"\nUnsupported instruction":""));}
 static byte[] readAll(InputStream in)throws IOException{ByteArrayOutputStream b=new ByteArrayOutputStream();byte[] x=new byte[65536];int n;while((n=in.read(x))>0)b.write(x,0,n);return b.toByteArray();}
}
