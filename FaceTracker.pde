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
  String[] names = {"Fred","Georgina","Alfred","Pembertine","Applebee's","Wildebeest","Squidzilla","Pomelo","Bob","Squiggledog","Constantine","Victoria","Mr. Bees n Berries"};
  
  Face(Rectangle faceData) {
    name = names[int(random(names.length))];
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
      overlay.noStroke();
      overlay.fill(faceColor);
      overlay.ellipseMode(CORNER);
      overlay.ellipse(xPos,yPos,faceWidth,faceHeight);
      if(showLabels){
        overlay.text(name,xPos+10,yPos+faceHeight+30);
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
  
}

class VisibleFace {
  Rectangle face;
  ArrayList<FaceMatch> matches;
  FaceMatch bestMatch;
  
  VisibleFace(Rectangle faceData, ArrayList<Face> stored) {
    face = faceData;
    matches = new ArrayList<FaceMatch>();
    for(Face f : stored){
      FaceMatch fm = new FaceMatch(f,this.face);
      matches.add(fm);
    }
    bestMatch = bestMatch();
  }
  
  void removeMatch(Face target) {
    for(FaceMatch m : matches){
      if(m.face==target);
      matches.remove(m);
      break;
    }
    if(matches.size()>0){
      bestMatch = bestMatch();
    }else{
      bestMatch = null;
    }
  }
  
  FaceMatch bestMatch() {
    int minDist = 100000;
    FaceMatch best = null;
    for(FaceMatch m : matches){
      if(m.distance<minDist){
        minDist = m.distance;
        best = m;
      }
    }
    return best; //Note that we could return null if bestMatch is called when matches is empty...
  }
}

class FaceMatch {
  Face face;
  int distance;
  
  FaceMatch(Face savedFace, Rectangle pos){
    face = savedFace;
    int dx = face.xPos-pos.x;
    int dy = face.yPos-pos.y;
    int dist = int(sqrt(dx*dx+dy*dy));
    distance = dist;
  }
}

class FaceTracker {
  ArrayList<Face> savedFaces;
  ArrayList<VisibleFace> visibleFaces;
  
  FaceTracker() {
    savedFaces = new ArrayList<Face>();
    visibleFaces = new ArrayList<VisibleFace>();
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
    for(Face f : savedFaces){
      f.droppedFrame = true;
    }
  }
  
  void processFaces(Rectangle[] facesToCheck) {
    println(facesToCheck.length+" faces to check");
    visibleFaces = new ArrayList<VisibleFace>();
    for (Rectangle r : facesToCheck){
      VisibleFace vf = new VisibleFace(r,savedFaces);
      visibleFaces.add(vf);
    }
  }
  
  void assignFaces() {
    int unassignedFaces = savedFaces.size();
    while(unassignedFaces>0){
      //If there aren't any visible faces left to assign, don't try to match any more saved faces
      if(visibleFaces.size()==0){
        break;
      }
      //Get best match from visFaces
      int minDist = 100000;
      VisibleFace best = null;
      for (VisibleFace vf : visibleFaces){
        int thisDist = vf.bestMatch.distance;
        if(thisDist<minDist){
          minDist = thisDist;
          best = vf;
        }
      }
      //Update proper storedFace
      if(best!=null){
        Face assignedFace = best.bestMatch.face;
        assignedFace.updateFace(best.face);
        //Remove visFace
        visibleFaces.remove(best);
        //Remove all faceMatches from remaining visFaces with same storedFace
        for(VisibleFace vf : visibleFaces){
          vf.removeMatch(assignedFace);
        }
        //Decrement unassignedFaces
        unassignedFaces--;
        println(unassignedFaces+" faces left to assign");
      }else{
        println("Something went wrong, there are no visible faces left to process...");
      }
    }
    //If visFaces still contains faces, add them to storedFaces
    if(visibleFaces.size()>0){
      for(VisibleFace vf : visibleFaces){
        addFace(vf.face);
      }
    }
  }
  
  void drawFaces() {
    println("Drawing "+savedFaces.size()+" face(s)");
    for(int i=0;i<savedFaces.size();i++){
      savedFaces.get(i).drawFace();
    }
  }
  
  Face addFace(Rectangle faceData) {
    Face newFace = new Face(faceData);
    println("Adding new face named "+newFace.name);
    savedFaces.add(newFace);
    return newFace;
  }
}
