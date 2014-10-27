import gab.opencv.*;
import processing.video.*;
import java.awt.*;

Capture video;
OpenCV opencv;
ArrayList<Face> storedFaces = new ArrayList<Face>();
Rectangle[] faces = {};
String[] names = {"Fred","Georgina","Alfred","Pembertine","Applebee's","Wildebeest","Squidzilla","Pomelo","Bob","Squiggledog","Constantine","Victoria","Mr. Bees n Berries"};
int scale = 2;

int stageWidth = 1440; int stageHeight = 900;

int faceAlphaMin = 40;
int faceAlphaMax = 200;
int faceAlpha = faceAlphaMin;

boolean showLabels = true;
boolean clearCanvas = true;
boolean showVideo = true;
boolean display = true;

FaceTracker tracker;

class Face {
  String name;
  int xPos;
  int yPos;
  int lastX;
  int lastY;
  float faceWidth;
  float faceHeight;
  color faceColor;
  boolean droppedFrame;
  
  
  Face(String faceName, Rectangle faceData) {
    name = faceName;
    xPos = faceData.x;
    yPos = faceData.y;
    lastX = xPos;
    lastY = yPos;
    faceWidth = faceData.width;
    faceHeight = faceData.height;
    faceColor = color(int(random(255)),int(random(255)),int(random(255)),faceAlpha);
    droppedFrame = false;
  }
  
  void drawFace() {
    if(droppedFrame){
      println("A saved face isn't visible");
      droppedFrame = false;
      faceColor = color(int(random(255)),int(random(255)),int(random(255)),faceAlpha);
    }else{
      noStroke();
      fill(faceColor);
      ellipseMode(CORNER);
      ellipse(xPos,yPos,faceWidth,faceHeight);
      //textMode(CENTER);
      if(showLabels){
        text(name,xPos+10,yPos+faceHeight+30);
      }
    }
  }
  
  void updateFace(Rectangle newData) {
    lastX = xPos;
    lastY = yPos;
    xPos = newData.x;
    yPos = newData.y;
    faceWidth = newData.width;
    faceHeight = newData.height;
    droppedFrame = false;
  }
  
  void findNearestFace(ArrayList<Rectangle> possibleFaces) {
    int closestDistance = 100000;
    int index = -1;
    for (int i=0;i<possibleFaces.size();i++) {
      Rectangle fr = possibleFaces.get(i);
      int dx = xPos-fr.x;
      int dy = yPos-fr.y;
      int dist = int(sqrt(dx*dx+dy*dy));
      if(dist<closestDistance){
        index = i;
        closestDistance = dist;
      }
    }
    if(index!=-1){
      updateFace(possibleFaces.get(index));
      possibleFaces.remove(index);
    }else{
      droppedFrame = true;
    }
    
  }
}

class FaceMatch {
  Face savedFace;
  Rectangle currentFace;
  int currentFaceIndex;
  int distance;
  
  FaceMatch(Face face, Rectangle pos, int visIndex, int dist){
    savedFace = face;
    currentFace = pos;
    distance = dist;
    currentFaceIndex = visIndex;
  }
}

class FaceTracker {
  ArrayList<Face> savedFaces;
  ArrayList<Rectangle> visibleFaces;
  ArrayList<FaceMatch> possibleMatches;
  
  FaceTracker() {
    savedFaces = new ArrayList<Face>();
    visibleFaces = new ArrayList<Rectangle>();
    possibleMatches = new ArrayList<FaceMatch>();
  }
  
  void update(Rectangle[] faces) {
    println("Untagging saved faces");
    untagFaces();
    println("Processing visible faces");
    processFaces(faces);
    println("Assigning visible faces to saved faces");
    assignFaces();
    println("Drawing faces");
    drawFaces();
  }
  
  void untagFaces() {
    for(int i=0;i<savedFaces.size();i++){
      savedFaces.get(i).droppedFrame = true;
    }
  }
  
  void processFaces(Rectangle[] facesToCheck) {
    println(facesToCheck.length+" faces to check");
    possibleMatches = new ArrayList<FaceMatch>();
    visibleFaces = new ArrayList<Rectangle>();
    for (int i=0;i<facesToCheck.length;i++) {
      visibleFaces.add(facesToCheck[i]);
      for(int j=0;j<savedFaces.size();j++){
        Rectangle nf = facesToCheck[i];
        Face sf = savedFaces.get(j);
        int dx = sf.xPos-nf.x;
        int dy = sf.yPos-nf.y;
        int dist = int(sqrt(dx*dx+dy*dy));
        possibleMatches.add(
          new FaceMatch(sf,nf,i,dist)
        );
      }
    }
  }
  
  void assignFaces() {
    int smallest = 100000;
    FaceMatch match;
    FaceMatch bestMatch = null;
    while(possibleMatches.size()>0){
      println(possibleMatches.size()+" possible matches left to check");
      smallest = 100000;
      bestMatch = null;
      for(int i=0;i<possibleMatches.size();i++){
        match = possibleMatches.get(i);
        if(match.distance<smallest){
          bestMatch = match;
          smallest = match.distance;
        }
      }
      if(bestMatch!=null){
        bestMatch.savedFace.updateFace(bestMatch.currentFace);
        visibleFaces.remove(bestMatch.currentFace);
        int[] toRemove ={};
        for(int i=0;i<possibleMatches.size();i++){
          match = possibleMatches.get(i);
          if(match.savedFace==bestMatch.savedFace || match.currentFace==bestMatch.currentFace){
            possibleMatches.remove(match);
          }
        }
        println(possibleMatches.size()+" matches left to process");
      }
    }
    println("There are "+visibleFaces.size()+" new faces visible");
    for(int i=0;i<visibleFaces.size();i++){
      addFace(visibleFaces.get(i));
    }
  }
  
  void drawFaces() {
    println("Drawing "+savedFaces.size()+" face(s)");
    for(int i=0;i<savedFaces.size();i++){
      savedFaces.get(i).drawFace();
    }
  }
  
  Face addFace(Rectangle faceData) {
    Face newFace = new Face(names[int(random(names.length))],faceData);
    println("Adding new face named "+newFace.name);
    savedFaces.add(newFace);
    return newFace;
  }
}

void checkFaces() {
  println("Checking "+faces.length+" faces");
  ArrayList<Rectangle> newFaces = new ArrayList<Rectangle>();
  for (int i=0;i<faces.length;i++){
    newFaces.add(faces[i]);
  }
  for (int i=0;i<storedFaces.size();i++){
    storedFaces.get(i).findNearestFace(newFaces);
  }
  for(int i=0;i<newFaces.size();i++) {
    addFace(newFaces.get(i));
  }
  for (int i = 0; i < storedFaces.size(); i++) {
    println("Drawing a face");
    storedFaces.get(i).drawFace();
  }
}

Face addFace(Rectangle faceData) {
  Face newFace = new Face(names[int(random(names.length))],faceData);
  println("Adding new face named "+newFace.name);
  storedFaces.add(newFace);
  return newFace;
}

void setup() {
  size(stageWidth, stageHeight);
  PFont f;
  f = createFont("Arial",16,true);
  textFont(f,36);
  video = new Capture(this, stageWidth/scale, stageHeight/scale);
  opencv = new OpenCV(this, stageWidth/scale, stageHeight/scale);
  opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);  

  tracker = new FaceTracker();
  
  video.start();
  frameRate(30);
}

void draw() {
  scale(2);
  opencv.loadImage(video);
  if(clearCanvas){background(255);}
  if(showVideo){image(video, 0, 0 );faceAlpha = faceAlphaMax;}else{faceAlpha = faceAlphaMin;}

  faces = opencv.detect();
  //println(faces.length);
  if(display){checkFaces();}//tracker.update(faces);}
  
  
    /*fill(0,180,200,233);
    stroke(0, 100, 200);
    strokeWeight(3);
    int xPos = faces[i].x;
    int yPos = faces[i].y;
    int faceWidth = faces[i].width;
    int faceHeight = faces[i].height;
    //println(faces[i].x + "," + faces[i].y);
    //rect(faces[i].x, faces[i].y, faces[i].width, faces[i].height);
    ellipseMode(CORNER);
    ellipse(xPos,yPos,faceWidth,faceHeight);
    float halfX = xPos+(faceWidth/2);
    float halfY = yPos+(faceHeight/2);
    float thirdX = xPos+(faceWidth/3);
    float thirdY = yPos+(faceHeight/3);
    float twoThirdsX = xPos+(2*faceWidth/3);
    float doubleHeight = yPos+faceHeight*2;
    float excitement = yPos+height/height;
    float exciteMod = excitement/86;
    println(exciteMod);
    float armsHigh = yPos+(faceHeight*(1.3*exciteMod));
    float armpit = yPos+faceHeight*1.5;
    float farLeft = xPos-(faceWidth*0.3);
    float farRight = xPos+(faceWidth*1.3);
    float feet = yPos + faceHeight*4;
    float eyecite = 8*(1/exciteMod);
    float eyeLength = (yPos+(1.5*faceHeight/3))+eyecite;
    float eyeStart = thirdY-eyecite;
    
    line(thirdX,eyeStart,thirdX,eyeLength);
    line(twoThirdsX,eyeStart,twoThirdsX,eyeLength);
    noFill();
    ellipseMode(CENTER);
    //Mouth
    arc(halfX,halfY,faceWidth*0.8,faceHeight*0.8,exciteMod,PI-exciteMod);
    fill(0,180,200,243);
    strokeWeight(6);
    
    //Spine and arms
    /*line(halfX,yPos+faceHeight+3,halfX,doubleHeight);
    line(halfX,armpit,farLeft,armsHigh);
    line(halfX,armpit,farRight,armsHigh);
    line(halfX,doubleHeight,farLeft,feet);
    line(halfX,doubleHeight,farRight,feet);*/
}

void keyReleased() {
  if(key=='c'){
    clearCanvas = !clearCanvas;
    if(clearCanvas == false){background(255);}
  }else if(key=='v'){
    showVideo = !showVideo;
  }else if(key=='l'){
    showLabels = !showLabels;
  }else if(key=='d'){
    display = !display;
    if(display == false){background(255);}
  }
}

void captureEvent(Capture c) {
  c.read();
}
