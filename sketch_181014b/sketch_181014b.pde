import processing.sound.*;



//Globals
ArrayList<Rectangle> outers1 = new ArrayList<Rectangle>();
ArrayList<Rectangle> outers2 = new ArrayList<Rectangle>();
Rectangle[] ra;
SoundFile sample;
Amplitude rms;
//Decrease sudden changes in amplitude
float smoothingFactor = 0.10;
float sf=0.01;
// Used for storing the smoothed amplitude value
float sum;
boolean alreadyClicked = false;
int lastClickTime = millis();


class Point {
  int x;
  int y;
  Point(int x1, int y1) {
    this.x=x1;
    this.y=y1;
  }
}

class Rectangle implements Comparable<Rectangle> {
  int x;
  int y;
  int w;
  int h;
  int ow;
  int oh;
  int ox;
  int oy;
  float alpha;
  long R = 0;
  long G = 0;
  long B = 0;
  float vx = 0;
  float vy = 0;
  int timeLasthit = 0;



  Rectangle(int ax, int ay, int aw, int ah, float alpha) {
    this.x = ax;
    this.y = ay;
    this.w = aw;
    this.h = ah;
    this.ow = aw;
    this.oh = ah;
    this.alpha=alpha;
    this.randomiseSpeed();
    this.ox=this.x;
    this.oy=this.y;
  }

  Rectangle(float ax, float ay, int aw, int ah, float alpha) {
    this.x = Math.round(ax);
    this.y = Math.round(ay);
    this.w = aw;
    this.h = ah;
    this.ow = aw;
    this.oh = ah;
    this.alpha=alpha;
    this.randomiseSpeed();
    this.vx=0;
    this.vy=0;
    this.ox=this.x;
    this.oy=this.y;
  }

  public int compareTo(Rectangle o) {
    return o.h;
  }

  void randomiseSpeed() {
    this.vx=random(-2, 2);
    this.vy=random(-2, 2);
  }

  void drawme() {
    noStroke();
    fill(R, G, B);
    pushMatrix();  
    translate(x, y);
    rotate(radians(alpha));
    rect(0, 0, w, h);
    popMatrix();
  }

  void drawme(float r1, float g1, float b1) {
    noStroke();
    fill(r1, g1, b1);
    pushMatrix();  
    translate(x, y);
    rotate(radians(alpha));
    rect(0, 0, w, h);
    popMatrix();
  }

  void setColours(float r1, float g1, float b1) {
    this.R=int(r1);
    this.G=int(g1);
    this.B=int(b1);
  }

  void setSpeed(float x, float y) {
    this.vx=Math.round(x);
    this.vy=Math.round(y);
  }
}



public boolean conflicts(Rectangle r, Rectangle[] ra) {
  for (Rectangle r1 : ra) {
    if (r1==null) {
      return false;
    }
    if (overlap(r1, r)) {
      return true;
    }
  }
  return false;
}

public boolean overlap(Rectangle r1, Rectangle r2) {
  return (0 >= dista(r1.x, r1.y, r2.x, r2.y)-(dista(r1.x, r1.y, r1.x-r1.h/2, r1.y-r1.w/2))-(dista(r2.x, r2.y, r2.x-r2.h/2, r2.y-r2.w/2)));
}

public double dista(int x1, int y1, int x2, int y2) {
  double dist = Math.sqrt((y2 - y1) * (y2 - y1) + (x2 - x1) * (x2 - x1));
  return dist;
}

public long calcColour(Rectangle rb, Rectangle r) {
  long val = 55;
  double pureDist=2*dista(rb.x, rb.y, rb.x-rb.h/2, rb.y-rb.w/2);
  double actualDist = dista(rb.x, rb.y, r.x, r.y);
  double diff=Math.abs(actualDist-pureDist);
  double div=diff/(2*pureDist);
  if (div>1) {
    div=1;
  }

  val = Math.round(255 * (1-(diff/(2*pureDist))));
  return val;
}

public Rectangle findClosest(Rectangle ro, Rectangle[] rs) {
  double minDist = Integer.MAX_VALUE;

  Rectangle rez = null;
  for (Rectangle rsr : rs) {
    if (minDist>dista(ro.x, ro.y, rsr.x, rsr.y)) {
      rez=rsr;
      minDist=dista(ro.x, ro.y, rsr.x, rsr.y);
    }
  }
  return rez;
}



public void CalculateColours(Rectangle[] ra) {
  int c = 3;
  for (Rectangle r : ra) {
    switch(c) {

    case 3:
      c--;
      r.R=255;
      break;

    case 2:
      c--;
      r.G=255;
      break;

    case 1:
      c--;
      r.B=255;
      break;

    default:
      boolean pureZoneRed=Math.round(dista(ra[0].x, ra[0].y, r.x, r.y))<2*Math.round(dista(ra[0].x, ra[0].y, ra[0].x-ra[0].h/2, ra[0].y-ra[0].w/2));
      boolean pureZoneGreen=Math.round(dista(ra[1].x, ra[1].y, r.x, r.y))<2*Math.round(dista(ra[1].x, ra[1].y, ra[1].x-ra[1].h/2, ra[1].y-ra[1].w/2));
      boolean pureZoneBlue=Math.round(dista(ra[2].x, ra[2].y, r.x, r.y))<2*Math.round(dista(ra[2].x, ra[2].y, ra[2].x-ra[2].h/2, ra[2].y-ra[2].w/2));

      r.R=calcColour(ra[0], r);//Razdalja od rdece svetlobe
      r.G=calcColour(ra[1], r);//Razdalja od zelene svetlove
      r.B=calcColour(ra[2], r);//Razdalja od plave svetlove

      if (pureZoneRed) {
        r.R=255;
      }
      if (pureZoneGreen) {
        r.G=255;
      }
      if (pureZoneBlue) {
        r.B=255;
      }
    }
  }
}

public void announce(String str) {
  fill(255);
  textSize(32);
  text(str, width*0.05, height*0.9);
}

void setup()
{

  fullScreen();
  //size(1200, 700);
  background(0);
  rectMode(CENTER);

  //Load and play a soundfile and loop it
  sample = new SoundFile(this, "alvaro_la_cintura.aiff");
  sample.loop();

  // Create and patch the rms tracker
  rms = new Amplitude(this);
  rms.input(sample);

  fill(255);
  //Total number of rectangles and size of the starting one
  //default 200
  int numrekts=200;
  //default 100
  int rektsize=100;
  //Parameter by which the next rectangle becomes smaller
  int minparam = 5;
  //The angle of rotation of each triangle
  int alpha = 42;
  Rectangle r = null;
  ra = new Rectangle[numrekts];
  for (int k = 0; k<ra.length; k++) {
    rektsize=rektsize-minparam;

    if (rektsize<0) {
      rektsize=25;
    }
    do {
      //To change area of rectangle spawning just adapt spawn zone variables here
      r=new Rectangle(random(100, width-100), random(100, height-100), rektsize, rektsize, random(0, 360));
    } while (conflicts(r, ra));
    pushMatrix();

    rotate(radians(alpha));
    popMatrix();
    ra[k]=r;
  }

  //Draw background here

  //Empty


  pushMatrix();


  //Colour calculation
  CalculateColours(ra);

  //Final rectangle drawing

  for (Rectangle rek : ra) {
    rek.drawme();
  }

  for (Rectangle rek : ra) {

    rek.h=rek.h*3/4;
    rek.w=rek.w*3/4;
    rek.drawme(0, 0, 0);
  }

  for (Rectangle rek : ra) {
    rek.h=rek.h/2;
    rek.w=rek.w/2;
    rek.drawme();
  }

  for (Rectangle rek : ra) {
    rek.h=rek.h/2;
    rek.w=rek.w/2;
    rek.drawme(0, 0, 0);
    rek.h=rek.oh;
    rek.w=rek.ow;
  }


  //Outer space greek lines drawing
  for (int j=0; j<2; j++) {
    int f=100;
    ArrayList<Rectangle> outers = new ArrayList<Rectangle>();
    int movement_unit=10;
    float startx=width;

    float starty=height-3*movement_unit;
    if (j==1) {
      starty=0+4*movement_unit;
    }
    int[] stages = {1, 2, 3};
    int cs = 2;
    int rand = int(random(1, 4));

    for (int k = 0; k<f; k++) {

      outers.add(new Rectangle(startx, starty, movement_unit, 10, 0));
      outers.add(new Rectangle(startx-movement_unit, starty, movement_unit, 10, 0));
      outers.add(new Rectangle(startx-2*movement_unit, starty, movement_unit, 10, 0));


      startx=startx-2*movement_unit;
      rand = int(random(1, 4));
      if (cs==2) {
        switch(rand) {
        case 1:
          starty=starty+movement_unit;
          cs=1;
          break;

        case 2:
          break;

        case 3:
          cs=3;
          starty=starty-movement_unit;
          break;
        }
      } else
        if (cs==3) {
          switch(rand) {
          case 1:
            outers.add(new Rectangle(startx, starty+movement_unit, movement_unit, 10, 0));
            starty=starty+2*movement_unit;
            cs=1;
            break;

          case 2:
            starty=starty+movement_unit;
            cs=2;
            break;

          case 3:

            break;
          }
        } else {
          //If it's stage 1
          switch(rand) {
          case 1:

            break;

          case 2:
            starty=starty-movement_unit;
            cs=2;
            break;

          case 3:
            outers.add(new Rectangle(startx, starty-movement_unit, movement_unit, 10, 0));
            starty=starty-2*movement_unit;
            cs=3;
            break;
          }
        }
    }

    //Colours of greek pattern
    for (Rectangle ro : outers) {
      if (ro==null) {
        break;
      } else {
        //Find closest rectangle to this cube
        Rectangle cr = findClosest(ro, ra);

        ro.drawme(cr.R+20, cr.G+20, cr.B+20);
      }
    }

    if (j==0) {
      outers1=outers;
    } else {
      outers2=outers;
    }
  }

  print("FINISH");

  //save("art.jpg");
  //Example of rotation
  //pushMatrix();  
  //translate(width/2,height/2);
  //rotate(radians(60));
  //rect(0,0,200,200);
  //popMatrix();
}

public void resetPositions() {
  for (Rectangle r : ra) {
    r.x=r.ox;
    r.y=r.oy;
    r.vy=0;
    r.vx=0;
  }
}

//Animation section

public boolean hitBoundsX(Rectangle rek) {
  return (rek.x>width || rek.x<0);
}

public boolean hitBoundsY(Rectangle rek) {
  return (rek.y>height || rek.y<0);
}

public void changeSpeedlocal(int mx, int my, int R) {
  for (Rectangle rek : ra) {
    if (dista(rek.x, rek.y, mx, my)<= R) {
      //Find where on x it is
      if (rek.x>=mx) {
        rek.vx=rek.vx+3.0;
      } else {
        rek.vx=rek.vx-3.0;
      }

      if (rek.y>=my) {
        rek.vy=rek.vy+3.0;
      } else {
        rek.vy=rek.vy-3.0;
      }
    }
  }
}

void draw() {

  background(10, 0, 0);

  //Colour calculation
  CalculateColours(ra);

  //Final rectangle drawing
  for (Rectangle rek : ra) {
    rek.drawme();
  }

  for (Rectangle rek : ra) {
    rek.h=rek.h*3/4;
    rek.w=rek.w*3/4;
    rek.drawme(0, 0, 0);
  }

  for (Rectangle rek : ra) {
    rek.h=rek.h/2;
    rek.w=rek.w/2;
    rek.drawme();
  }

  for (Rectangle rek : ra) {
    rek.h=rek.h/2;
    rek.w=rek.w/2;
    rek.drawme(0, 0, 0);
    rek.h=rek.oh;
    rek.w=rek.ow;
  }


  //Colours of greek pattern - bottom one
  for (Rectangle ro : outers1) {
    if (ro==null) {
      break;
    } else {
      //Find closest rectangle to this cube
      Rectangle cr = findClosest(ro, ra);

      ro.drawme(cr.R+20, cr.G+20, cr.B+20);
    }
  }

  //Colours of greek pattern - top one
  for (Rectangle ro : outers2) {
    if (ro==null) {
      break;
    } else {
      //Find closest rectangle to this cube
      Rectangle cr = findClosest(ro, ra);

      ro.drawme(cr.R+20, cr.G+20, cr.B+20);
    }
  }

  //Check if speed changed
  for (Rectangle rek : ra) {

    //If it hit the walls
    if (hitBoundsX(rek)) {
      rek.vx=-rek.vx;
    }
    if (hitBoundsY(rek)) {
      rek.vy=-rek.vy;
    }

    //If it hit other cubes
    //for (Rectangle rek2 : ra) {

    //  if ( ! (rek2==rek)) {
    //    if (overlap(rek, rek2)) {
    //      if ((millis()-rek.timeLasthit)>2000)
    //        rek.alreadyHit=false;
    //      if (! rek.alreadyHit) {
    //        rek.alreadyHit=true;
    //        //rek.setSpeed(-rek.vx, -rek.vy);
    //        //rek2.setSpeed(-rek2.vx, -rek2.vy);
    //        rek.timeLasthit = millis();
    //      }
    //    }
    //  }
    //}
  }

  if (abs(lastClickTime-millis())>300) {
    alreadyClicked=false;
  }

  if (mousePressed) {
    if (! alreadyClicked) {
      alreadyClicked=true;
      lastClickTime=millis();
      changeSpeedlocal(mouseX, mouseY, 100);
      announce("Explosion click");
    } else {
      announce("Explosion click ");
    }
  }

  if (keyPressed) {
    switch(key) {

      //Assign new random speed
    case 'r':
      for (Rectangle rek : ra) {
        rek.randomiseSpeed();
      }
      announce("R - Speed randomised");
      break;
    case 'q':
      smoothingFactor=smoothingFactor+0.0005;
      if (smoothingFactor>1) {
        smoothingFactor=1;
      }
      announce("Q - Smoothing factor increased "+smoothingFactor);
      break;
    case 'a':
      smoothingFactor=smoothingFactor-0.0005;
      if (smoothingFactor<0) {
        smoothingFactor=0;
      }
      announce("A - Smoothing factor decreased "+smoothingFactor);
      break;
    case 'e':
      sf=sf+0.00005;
      announce("E - Size increased "+sf);
      break;
    case 'd':
      sf=sf-0.00005;
      if (sf<0) {
        sf=0;
      }
      announce("D - Size decreased "+sf);
      break;
    case 't':
      resetPositions();
      announce("T - positions reset");
      break;

    case 'z':
      for (Rectangle rek : ra) {
        rek.vx=rek.vx*1.01;
        rek.vy=rek.vy*1.01;

      }
      announce("Z - speeding up");
      break;
    case 'h':
      for (Rectangle rek : ra) {
        rek.vx=rek.vx*0.99;
        rek.vy=rek.vy*0.99;

      }
      announce("H - slowing down");
      break;
    }
  }


  sum += (rms.analyze() - sum) * smoothingFactor;

  // rms.analyze() return a value between 0 and 1. It's
  // scaled to height/2 and then multiplied by a fixed scale factor
  for (Rectangle rek : ra) {
    rek.h=rek.oh;
    rek.w=rek.ow;
    float rms_scaled = sum * (height/2) * rek.oh*sf;
    rek.w=Math.round(rms_scaled);
    rek.h=Math.round(rms_scaled);
  }


  //Move rects
  for (Rectangle rek : ra) {
    rek.x=rek.x+Math.round(rek.vx);
    rek.y=rek.y+Math.round(rek.vy);
  }
}
