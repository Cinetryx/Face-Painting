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

//Face class to track position and stats of face with methods to draw the face to the screen
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

//A class to keep track of possible matches between visible faces and stored faces
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

//A class to keep track of faces in memory, and match visible faces to saved ones
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
  //Load video frame into opencv
  opencv.loadImage(video);
  if(clearCanvas){background(255);}
  if(showVideo){image(video, 0, 0 );faceAlpha = faceAlphaMax;}else{faceAlpha = faceAlphaMin;}
  
  //Find faces in frame
  faces = opencv.detect();
  
  //Match current faces with saved faces
  if(display){checkFaces();}//tracker.update(faces);}
}
//Track user input
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
