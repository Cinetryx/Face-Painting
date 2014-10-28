import gab.opencv.*;
import processing.video.*;
import java.awt.*;

PGraphics overlay;

Capture video;
OpenCV opencv;
Rectangle[] faces = {};
int scale = 2;

int stageWidth = 1440; int stageHeight = 900;

int faceAlphaMin = 7;
int faceAlphaMax = 160;
int faceAlpha = faceAlphaMin;

boolean showLabels = false;
boolean clearCanvas = true;
boolean showVideo = false;
boolean display = true;


void setup() {
  size(stageWidth, stageHeight);
  PFont f;
  f = createFont("Arial",16,true);
  textFont(f,36);
  video = new Capture(this, stageWidth/scale, stageHeight/scale);
  opencv = new OpenCV(this, stageWidth/scale, stageHeight/scale);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);  

  tracker = new FaceTracker();
  
  overlay = createGraphics(stageWidth,stageHeight);
  
  video.start();
  frameRate(30);
}

void draw() {
  scale(2);
  
  opencv.loadImage(video);
  overlay.beginDraw();
  if(clearCanvas){overlay.background(255,255,255,0);}
  if(showVideo){image(video,0,0 );faceAlpha = faceAlphaMax;}else{faceAlpha = faceAlphaMin;}

  faces = opencv.detect();
  if(display){tracker.update(faces);}
  overlay.endDraw();
  image(overlay,0,0);
  
}

void keyReleased() {
  if(key=='c'){
    clearCanvas = !clearCanvas;
    if(clearCanvas == true){overlay.background(255);}
  }else if(key=='v'){
    showVideo = !showVideo;
  }else if(key=='l'){
    showLabels = !showLabels;
  }else if(key=='d'){
    display = !display;
    if(display == true){overlay.background(255);}
  }
}

void captureEvent(Capture c) {
  c.read();
}
