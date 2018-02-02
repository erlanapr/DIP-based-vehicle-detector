//import processing.video.*;
import ipcapture.*;
import g4p_controls.*;

int BOXSIZE = 160;
float GREYTHRESHOLD = 22;
int BOXCOUNTTHRESHOLD = 150;
int DIFFBOXCOUNT = 50;
float XCTHRESHOLD = 0.64;
//float HUMANTHRESHOLD = 0.48;
int DIRRR = 3;          //closeness index for floodfill
int MAXCT = 20;
boolean DISPLAYBOX = false;
boolean DISPLAYFLOOD = false;
boolean DISPLAYBLACKBOX = true;
boolean CORRELATE = true;
boolean PATCHHOLES = true;
boolean BRUTEPATCH = true;
float TIMEDELAY = 0.5; 
boolean reset = false;
boolean AUTORESET = false;

int autoresetThreshold = 5;
int frameCounter = 0;

//Capture vid;
IPCapture vid;
BoxRGB[][] boxes = new BoxRGB[160][160];
BoxRGB[][] firstFrame = new BoxRGB[160][160];
boolean[][] diffBoxSmall = new boolean[160][160];
FlooderClass[] flooder = new FlooderClass[DIFFBOXCOUNT];
float pixelsPerBox;

int types = 3;
XCorrReference[] xc = new XCorrReference[types];
int[] vehicleCounter = new int[types];
int[] matchesCount = new int[types];

double prev=0, meantime=0, timee=0, now=0, proctime=0, procmean=0;
boolean ready = false;
int ctr = 0, timeidx = 0;
double[] times = new double[100];
double[] proctimes = new double[100];

void setup()
{
  size(1000, 480);
  println("bismillah");

  for (int i = 0; i < DIFFBOXCOUNT; i++) flooder[i] = new FlooderClass();
  for (int i = 0; i < 160; i++)
    for (int j = 0; j < 160; j++)
    {
      boxes[i][j] = new BoxRGB();
      firstFrame[i][j] = new BoxRGB();
    }

  /*-------------------------------CORRELATION REFFERENCE----------------------------*/
   
  xc[0] = new XCorrReference("mobil4.jpg");
  xc[0].txt = "mobil";
  xc[1] = new XCorrReference("motor2.jpg");
  xc[1].txt = "motor";
  xc[2] = new XCorrReference("truk.jpg");
  xc[2].txt = "truk";
  xc[0].count = 36;
  xc[1].count = 49;
  xc[2].count = 1;

  /*--------------------------------------------------------------------------------*/

  for (int d=0; d<types; d++) println(xc[d].mean);
}

void draw()
{
  if (startup(ctr++))
  {
    //if (vid.available())

    //background(0);
    now = millis();
    for (int i = timeidx - 2; i >= 0; i--)
    {
      times[i+1] = times[i];
      proctimes[i+1] = proctimes[i];
    }
    times[0] = now - prev;
    proctimes[0] = proctime;
    meantime = 0; 
    procmean = 0;
    for (int i = 0; i < timeidx; i++)
    {
      meantime += times[i];
      procmean += proctimes[i];
    }
    meantime /= timeidx;
    procmean /= timeidx;
    if (timeidx < 10) timeidx++;
    prev = millis();
    vid.read();
    vid.loadPixels();
    background(222);
    for (int a = 0; a < BOXSIZE; a++) //loop up -> bot
    {
      for (int b = 0; b < BOXSIZE; b++)// loop left -> right
      {
        float Rsum = 0, Gsum=0, Bsum=0;
        int cbegin = a*(vid.height/BOXSIZE);
        for (int c = cbegin; c < cbegin+(vid.height/BOXSIZE); c++)
        {
          int dbegin = b*(vid.width/BOXSIZE);
          for (int d = dbegin; d < dbegin+(vid.width/BOXSIZE); d++)
          {
            int col = vid.pixels[c*vid.width+d];
            Rsum += (float)(col >> 16 & 0xFF);
            Gsum += (float)(col >> 8 & 0xFF);
            Bsum += (float)(col & 0xFF);
          }
        }
        boxes[a][b].R = Rsum / pixelsPerBox;
        boxes[a][b].G = Gsum / pixelsPerBox;
        boxes[a][b].B = Bsum / pixelsPerBox;
      }
    }

    image(vid, 0, 0, vid.width, vid.height);
    fill(255);
    noStroke();
    rect(930, 455, 80, 50);
    rect(930, 435, 80, 50);
    textFont(loadFont("TrebuchetMS-14.vlw"));
    fill(0);
    stroke(0);
    textAlign(LEFT);
    String tx = String.format("%.2f", meantime) + " ms";
    text(tx, 940, 470);
    tx = "spf";
    text(tx, 905, 470);
    tx = String.format("%.2f", procmean) + " ms";
    text(tx, 940, 450);
    tx = "proc time";
    text(tx, 865, 450);
    tx = String.format("%.2f", 1000.0/(float)meantime) + " fps";
    text(tx, 650, 470);
    //displayUI();

	//diffboxsmal = position of differences between 'boxes' and 'firstFrame'
    for (int a = 0; a < BOXSIZE; a++)
      for (int b = 0; b < BOXSIZE; b++)
      {
        boolean x = abs(boxes[a][b].R - firstFrame[a][b].R) > GREYTHRESHOLD;
        boolean y = abs(boxes[a][b].G - firstFrame[a][b].G) > GREYTHRESHOLD;
        boolean z = abs(boxes[a][b].B - firstFrame[a][b].B) > GREYTHRESHOLD;
        if (x || y || z)
        {
          diffBoxSmall[a][b] = true;
        }
      }

    boolean allClear;
    int idx = 0;
    do
    {
      floodFill(flooder[idx]);
      if (flooder[idx].used) idx++;
      allClear = true;
      for (int a = 0; a < BOXSIZE; a++)
        for (int b = 0; b < BOXSIZE; b++)
          if (diffBoxSmall[a][b])
            allClear = false;
    } 
    while (!allClear && idx < DIFFBOXCOUNT);

    idx = 0;
    while (flooder[idx++].count != 0 && idx < 12);
    text("Area:", 920, 330);
    text(str(idx-1), 980, 330);
    while (idx < 12) flooder[idx++].reset();

    //while(flooder[x].used) xcorr(flooder[x++],xc[0]);

    /*
      textFont(loadFont("TrebuchetMS-12.vlw"));
     fill(0);
     text(str(flooder[0].count), 700, 338);
     text(str(flooder[1].count), 700, 358);
     text(str(flooder[2].count), 700, 378);
     text(str(flooder[3].count), 700, 398);
     text(str(flooder[4].count), 700, 418);
     text(str(flooder[5].count), 700, 438);
     */
    //int[] currentMatchesCount = new int[types];

    if (CORRELATE)
    {
      int[] currentMatchesCount = new int[types];
      for (int a = 0; a < 6; a++)
      {
        boolean drawn = false;
        if (flooder[a].count == 0) continue;
        for (int b = 0; b < types; b++)
        {
          xc[b].val = xcorr(flooder[a], xc[b], drawn);
          drawn = true;
        }

        //only highest count
        idx = 0;
        float max = xc[0].val;
        for (int i = 1; i < types; i++)
          if (max < xc[i].val)
          {
            max = xc[i].val;
            idx = i;
          }
          
        if (xc[idx].val > XCTHRESHOLD)
        {
          currentMatchesCount[idx]++;
          fill(0, 128, 255);
          textFont(loadFont("Trebuchet-BoldItalic-16.vlw"));
          text(xc[idx].txt, flooder[a].center[1], flooder[a].center[0]);
          text(xc[idx].val, flooder[a].center[1], flooder[a].center[0]+20);
        }
      }
      
      
      //for(int i = 0; i < types; i++) println(i + "\t" + currentMatchesCount[i]);
        
      for (int i = 0; i < types; i++)
      {
        if (currentMatchesCount[i] == matchesCount[i])
          //for(int j = 0; j < 3; j++)
          xc[i].lastrecord = 0;
        else if (currentMatchesCount[i] > matchesCount[i])
        {
          xc[i].delta = currentMatchesCount[i] - matchesCount[i];
          xc[i].count += xc[i].delta;
          matchesCount[i] = currentMatchesCount[i];
          xc[i].XFont = loadFont("TrebuchetMS-Bold-14.vlw");
        } else if (currentMatchesCount[i] < matchesCount[i])
        {
          if (xc[i].lastrecord == 0)
            xc[i].lastrecord = millis();
        }

        if (xc[i].lastrecord != 0)
          if (millis() - xc[i].lastrecord > TIMEDELAY*1000)
            matchesCount[i] -= xc[i].delta;
      }
      

      /*
      for (int i = 0; i < types; i++)
       {
       for (int j = 0; j < 3; j++)        
       if (xc[i].lastrecords[j] == 0) continue;
       else if (millis() - xc[i].lastrecords[j] > TIMEDELAY*1000)
       {
       xc[i].lastrecords[j] = 0;
       matchesCount[i] -= xc[i].delta[j];
       }
       if (currentMatchesCount[i] > matchesCount[i])
       {
       int k = 0;
       while (k < 3) if (xc[i].lastrecords[k++] == 0) break;
       if (k <= 3) xc[i].lastrecords[k-1] = millis();
       xc[i].delta[k-1] = currentMatchesCount[i] - matchesCount[i];
       xc[i].count += xc[i].delta[k-1];
       matchesCount[i] = currentMatchesCount[i];
       xc[i].XFont = loadFont("TrebuchetMS-Bold-14.vlw");
       }
       }
       */
      //delta = new int[types];
    }

    if (AUTORESET)
    {
      boolean add = true;
      for (int a = 0; a < types; a++)
      {
        if (xc[a].val > XCTHRESHOLD)
          add = false;
      }
      if (add) frameCounter++;
      else frameCounter = 0;

      if (frameCounter > autoresetThreshold)
      {
        reset = true;
        frameCounter = 0;
      }
    }

    fill(0);
    for (int a = 0; a < types && a < 6; a++)
    {
      textFont(xc[a].XFont);
      text(xc[a].txt, 650, 338+20*a);
      text(xc[a].count, 710, 338+20*a);
      xc[a].XFont = loadFont("TrebuchetMS-12.vlw");
    }
    for (int a = 6; a < types && a < 12; a++)
    {
      textFont(xc[a].XFont);
      text(xc[a].txt, 730, 338+20*(a-6));
      text(xc[a].count, 800, 338+20*(a-6));
      xc[a].XFont = loadFont("TrebuchetMS-12.vlw");
    }

    proctime = millis() - now;   

    //text(String.format("%.4f",xcorr(flooder[0],xc[0])),765,324);
    //text(String.format("%.4f",xcorr(flooder[0],xc[1])),810,324);
    //text(String.format("%.4f",xcorr(flooder[0],xc[2])),855,324);
  } else delay(50);
}

boolean startup(int ctr)
{
  if (ready && !reset)
  {
    ctr--; 
    return ready;
  }

  if (ctr < 1)
  {
    //vid = new Capture(this, 640, 480);
    //vid = new Capture(this, 640, 480, "USB2.0 PC CAMERA");
    //vid = new IPCapture(this, "http://192.168.43.1:8080/video", "thecam", "poipoipoi");
    vid = new IPCapture(this, "http://192.168.137.142:8080/video","thecam","poipoipoi");
    //vid = new IPCapture(this, "http://192.168.100.15:8080/video","","");
    pixelsPerBox = (vid.height/BOXSIZE)*(vid.width/BOXSIZE);
    vid.start();
  }

  //trash some
  if (ctr <= MAXCT && !reset)
  {
    //println("trashing",2*(ctr+1), "%");
    //while (!vid.available());
    vid.read();
    background(100);
    stroke(0);
    fill(255);
    rect(120, 240, (width - 240), 20);
    fill(0, 100, 150);
    rect(120, 240, ((float)ctr/(float)MAXCT)*(width-240), 20);
    fill(255);
    textFont(loadFont("TrebuchetMS-24.vlw"));
    String tx =  int((float)ctr/(float)MAXCT*100.0)+"%";
    text(tx, width/2, 270, 50, 50);
    return ready;
  }

  //load firstframe
  vid.loadPixels();
  background(0);
  for (int a = 0; a < BOXSIZE; a++) //loop up -> bot
  {
    for (int b = 0; b < BOXSIZE; b++)// loop left -> right
    {
      float Rsum = 0, Gsum=0, Bsum=0;
      int cbegin = a*(vid.height/BOXSIZE);
      for (int c = cbegin; c < cbegin+(vid.height/BOXSIZE); c++)
      {
        int dbegin = b*(vid.width/BOXSIZE);
        for (int d = dbegin; d < dbegin+(vid.width/BOXSIZE); d++)
        {
          int col = vid.pixels[c*vid.width+d];
          Rsum += (float)(col >> 16 & 0xFF);
          Gsum += (float)(col >> 8 & 0xFF);
          Bsum += (float)(col & 0xFF);
        }
      }
      firstFrame[a][b].R = Rsum / pixelsPerBox;
      firstFrame[a][b].G = Gsum / pixelsPerBox;
      firstFrame[a][b].B = Bsum / pixelsPerBox;
    }
  }
  ready = true;
  if (reset)
  {
    reset = false;
    return ready;
  }
  createGUI();
  return ready;
}

void floodFill(FlooderClass FL)
{
  FL.reset();
  int[][] f = new int [BOXSIZE][BOXSIZE];  
  int dirCount = (DIRRR == 0) ? 4 : ((2*DIRRR + 1)*(2*DIRRR + 1) - 1); //(2x+1)^2 - 1
  int[][] dir = new int[dirCount][2];
  int z = 0;
  for (int i = -DIRRR; i <= DIRRR; i++)
    for (int j = -DIRRR; j <= DIRRR; j++)
    {
      if (i == 0 && j == 0) continue;
      dir[z][0] = i;
      dir[z][1] = j;
      z++;
    }

  int[] pos = {0, 0};    
  boolean done = false;
  for (int a = 0; a < BOXSIZE; a++)
  {
    if (done) break;
    for (int b = 0; b < BOXSIZE; b++)
    {
      if (done) break;
      if (diffBoxSmall[a][b])
      {
        pos[0] = a;
        pos[1] = b;
        diffBoxSmall[a][b] = false;
        done = true;
      }
    }
  }

  done = false;
  while (!done)
  {
    int y = pos[0];
    int x = pos[1];
    (f[y][x])++;
    //if (f[y][x] == 0) f[y][x] = 2;
    //else if (f[y][x] == 2) f[y][x] = 1;
    //2: sudah terlewati, blum cek tetangga
    //1: sudah cek tetangga

    boolean succes = false;
    for (int i = 0; i < dirCount; i++)
    {
      int oldy = pos[0];

      int oldx = pos[1];
      int newy = pos[0] + dir[i][0];
      int newx = pos[1] + dir[i][1];
      if (newx >= BOXSIZE || newy >= BOXSIZE) continue;
      if (newx < 0 || newy < 0) continue;
      if (diffBoxSmall[newy][newx] && (f[newy][newx] == 0))
      {
        pos[0]=newy;
        pos[1]=newx;
        diffBoxSmall[newy][newx] = false;
        succes = true;
        if (BRUTEPATCH)
        {
          if (abs(newy-oldy) > 1 || abs(newx-oldx) > 1)
          {
            boolean orientasi = (abs(newy-oldy) > abs(newx-oldx)) ? true : false; //T=y,F=x
            int diry = (oldy >= newy) ? 1 : -1;
            int dirx = (oldx >= newx) ? 1 : -1;
            if (orientasi) //y
              for (int a = newy+diry; abs(a-oldy) > 0; a+=diry)
              {
                if (a < 0 || a >= BOXSIZE) continue;
                for (int b = newx; ((newx > oldx) ? b-oldx : oldx-b) >= 0; b += dirx)
                {
                  if (b < 0 || b >= BOXSIZE) continue;
                  if (!diffBoxSmall[a][b])
                    f[a][b] = 1;
                }
              }
            if (!orientasi) //x
            {
              for (int a = newy; ((newy > oldy) ? a-oldy : oldy-a) >= 0; a+= diry)
              {
                if (a < 0 || a >= BOXSIZE) continue;
                for (int b = newx+dirx; abs(b-oldx) > 0; b+= dirx)
                {
                  if (b < 0 || b >= BOXSIZE) continue;
                  if (!diffBoxSmall[a][b])
                    f[a][b] = 1;
                }
              }
            }
          }
        }
        break;
      }
    }

    if (!succes)
    {
      for (int a = 0; a < BOXSIZE; a++)
      {
        if (succes) break;
        for (int b = 0; b < BOXSIZE; b++)
        {
          if (f[a][b] == 1)
          {
            pos[0] = a; //y
            pos[1] = b; //x
            succes = true;
            break;
          }
        }
      }
    }
    if (!succes) done = true;
  }

  //display
  for (int a=0; a<BOXSIZE; a++)
    for (int b=0; b<BOXSIZE; b++)
      if (f[a][b] > 0)
      {
        FL.setNew(a, b);
        FL.count++;
        //rect(b*width/BOXSIZE,a*height/BOXSIZE,width/BOXSIZE,height/BOXSIZE);
      }

  if (FL.count < BOXCOUNTTHRESHOLD)
  {
    FL.reset();
    return;
  }

  //tambal lobang
  int[][] holdir = {{-1, 0}, {0, -1}, {0, 1}, {1, 0}};
  pos = new int[] {0, 0};
  boolean finish = false;
  int xmin = FL.xmin * BOXSIZE/vid.width;
  int xmax = FL.xmax * BOXSIZE/vid.width;
  int ymin = FL.ymin * BOXSIZE/vid.height;
  int ymax = FL.ymax * BOXSIZE/vid.height;
  ymax++;   
  xmax++;

  int[][] holes = new int[BOXSIZE][BOXSIZE];
  for (int a = ymin; a < ymax; a++)
  {
    if (finish) break;
    for (int b = xmin; b < xmax; b++)
    {
      if (finish) break;
      if (!FL.pos[a][b])
      {
        pos[0] = a;
        pos[1] = b;
        finish = true;
      }
    }
  }

  if (PATCHHOLES)
  {
    done = false;
    while (!done)
    {
      finish = false;
      while (!finish)
      {
        int y = pos[0];
        int x = pos[1];
        holes[y][x]++;
        boolean succes = false;
        for (int i = 0; i < 4; i++)
        {
          int newy = pos[0] + holdir[i][0];
          int newx = pos[1] + holdir[i][1];
          if (newx >= xmax || newy >= ymax) continue;
          if (newx < xmin || newy < ymin) continue;
          if (holes[newy][newx] == 0 && !FL.pos[newy][newx])
          {
            pos = new int[] {newy, newx};
            succes = true;
            break;
          }
        }

        if (!succes)
        {
          for (int a = ymin; a < ymax; a++)
          {
            if (succes) break;
            for (int b = xmin; b < xmax; b++)
            {
              if (holes[a][b] == 1 || holes[a][b] == 2)
              {
                pos = new int[] {a, b};
                succes = true;
                break;
              }
            }
          }
        }
        if (!succes) finish = true;
      }
      boolean cek = true;
      for (int a = ymin; a < ymax; a++)
      {
        if (holes[a][xmin] == 3)     cek = false;
        if (holes[a][xmax - 1] == 3) cek = false;
      }
      for (int a = xmin; a < xmax; a++)
      {
        if (holes[ymin][a] == 3)     cek = false;
        if (holes[ymax - 1][a] == 3) cek = false;
      }

      for (int a = ymin; a < ymax; a++)
        for (int b = xmin; b < xmax; b++)
          if (holes[a][b] == 3)
          {
            if (cek)
            {
              holes[a][b] = 4;
              FL.pos[a][b] = true;
              FL.setNew(a, b);
              FL.count++;
              //println(new int[]{a,b});
            }
            if (!cek)
            {
              holes[a][b] = 5;
            }
          }

      //find startpos for new hole floodfill
      done = false;
      finish = false;
      for (int a = ymin; a < ymax; a++)
      {
        if (finish) break;
        for (int b = xmin; b < xmax; b++)
        {
          if (finish) break;
          if (holes[a][b] == 0 && !FL.pos[a][b])
          {
            pos = new int[] {a, b};
            finish = true;
          }
        }
      }
      if (!finish) done = true;
    }
  }

  stroke(0, 200, 0);
  fill(0, 255, 0, 30);
  strokeWeight(1);
  if (DISPLAYBOX)
    for (int a = 0; a < BOXSIZE; a++)
      for (int b = 0; b < BOXSIZE; b++)
        if (FL.pos[a][b])
          rect(b*vid.width/BOXSIZE, a*vid.height/BOXSIZE, vid.width/BOXSIZE, vid.height/BOXSIZE);
  noFill();
  stroke(0);
  if (DISPLAYFLOOD) FL.display();
  FL.displayCenter();
}
