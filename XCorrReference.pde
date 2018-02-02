class XCorrReference
{
  float[][] pix;
  PImage imag;
  int width, height;
  float mean;  
  String txt;
  int count;
  long lastrecord;
  int delta;
  PFont XFont;
  float val;
  XCorrReference(String imageName)
  {
    imag = loadImage(imageName);
    pix = new float[imag.height][imag.width];
    width = imag.width;
    height = imag.height;
    count = 0;
    delta = 0;
    XFont = loadFont("TrebuchetMS-12.vlw");
    mean = 0;
    for (int a = 0; a < imag.height; a++)
      for (int b = 0; b < imag.width; b++)
      {
        int col = imag.pixels[a*width+b];
        float R = (float)(col >> 16 & 0xFF);
        float G = (float)(col >> 8 & 0xFF);
        float B = (float)(col & 0xFF);
        float gray = (R+G+B)/3.0;
        mean += gray;
        pix[a][b] = gray;
      }
    mean /= (imag.height*imag.width);
  }
}

float xcorr(FlooderClass FL, XCorrReference XC, boolean drawn)
{
  //rect(FL.xmin,FL.ymin,FL.xmax-FL.xmin,FL.ymax-FL.ymin);
  PImage pimg = createImage(FL.xmax - FL.xmin + vid.width/BOXSIZE, FL.ymax - FL.ymin + vid.height/BOXSIZE, RGB);
  int cs = FL.ymin * BOXSIZE / vid.height;
  int ds = FL.xmin * BOXSIZE / vid.width;

  for (int a = 0; a < BOXSIZE; a++)
    for (int b = 0; b < BOXSIZE; b++)
    {
      if (!FL.pos[a][b]) continue;
      int cstart = (a - cs)*vid.height/BOXSIZE;
      int dstart = (b - ds)*vid.width/BOXSIZE;
      for (int c = cstart; c < cstart + vid.height/BOXSIZE; c++)
        for (int d = dstart; d < dstart + vid.width/BOXSIZE; d++)
          pimg.pixels[c*pimg.width + d] = 0xFFFFFF;
    }

  if (DISPLAYBLACKBOX)
    if (!drawn) 
      image(pimg, FL.xmin, FL.ymin);
  pimg.resize(XC.width, XC.height);
  float[][] data = new float[XC.height][XC.width];

  int idx = 0;
  float meandata = 0;
  for (int a = 0; a < XC.height; a++)
    for (int b = 0; b < XC.width; b++)
    {
      //if(pimg.pixels[idx] > 0x7FFFFF) data[a][b] = 255;
      //else data[a][b] = 0;
      int col = pimg.pixels[idx];
      float R = float(col >> 16 & 0xFF);
      float G = float(col >> 8 & 0xFF);
      float B = float(col & 0xFF);
      data[a][b] = (R+G+B)/3;

      meandata += data[a][b];
      idx++;
    }
  meandata = meandata/(pimg.height*pimg.width);
  //for(int a = 0; a < XC.height; a++)
  //  for(int b = 0; b < XC.width; b++)
  //  {
  //    fill(data[a][b]);
  //    stroke(data[a][b]);
  //    point(b,a);
  //  }

  float nom = 0;
  float den1 = 0;
  float den2 = 0;

  for (int y = 0; y < XC.height; y++)
    for (int x = 0; x < XC.width; x++)
    {
      nom += ((data[y][x] - meandata) * (XC.pix[y][x] - XC.mean));
      den1 += ((data[y][x] - meandata) * (data[y][x] - meandata));
      den2 += ((XC.pix[y][x] - XC.mean) * (XC.pix[y][x] - XC.mean));
    }

  float res = nom/sqrt(den1*den2);
  return res;
}
