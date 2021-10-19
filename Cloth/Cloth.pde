//Create Window
String windowTitle = "Cloth_simulation";
void setup() {
  size(1000, 1000, P3D);
  surface.setTitle(windowTitle);
  camera = new Camera();
  img =  loadImage("sheet.jpg");
   
  initScene();
}

//Simulation Parameters
Camera camera;
boolean debug = false;
PImage img; 
Vec3 gravity = new Vec3(0,1,0);
float radius = 4;
float obstacleSphere = 50;
Vec3 stringTop = new Vec3(500,-10,0);
float restLen = 6;
float mass = 1; 
float k = 5; 
float kv = 10; 
Vec3 spherePos = new Vec3(500,180,85);

//Initial positions and velocities of masses
static int maxNodesRow = 100;
static int maxNodesColomn = 100;
Vec3 pos[][] = new Vec3[maxNodesRow][maxNodesColomn];
Vec3 vel[][] = new Vec3[maxNodesRow][maxNodesColomn]; 
Vec3 acc[][] = new Vec3[maxNodesRow][maxNodesColomn];

int numNodes = 30;

void initScene(){
  for (int i = 0; i < numNodes; i++){
    for(int j = 0; j < numNodes; j++){
      pos[i][j] = new Vec3(0,0,0);
      pos[i][j].x = stringTop.x + (i-(numNodes/2-1))*6;
      pos[i][j].y = stringTop.y + (j-0)*6; //Make each node a little lower
      pos[i][j].z = j*10;
      vel[i][j] = new Vec3(0,0,0);
    }
  }
}

void update(float dt){
  //clean accelaration 
  for (int i = 0; i < numNodes; i++){
     for(int j = 0; j < numNodes; j++){
       acc[i][j] = new Vec3(0,0,0);
       acc[i][j].add(gravity);
     }
  }
  
  //vertical string force and damper force
  for (int i = 0; i < numNodes; i++){
    for(int j = 0; j < numNodes-1; j++){
      Vec3 e = pos[i][j+1].minus(pos[i][j]);
      float currentLen = e.length();
      e = e.normalized();
      //System.out.println(e);
      float v1 = dot(e, vel[i][j]);
      float v2 = dot(e, vel[i][j+1]);
      float stringF = -k*(currentLen-restLen);
      float dampF = -kv*(v2-v1);
      Vec3 force = e.times(stringF+dampF);
      acc[i][j].add(force.times(-1.0/mass));
      acc[i][j+1].add(force.times(1.0/mass));
    }
  }
  
  //horizontal string force and damper force
  for (int i = 0; i < numNodes-1; i++){
    for(int j = 0; j < numNodes; j++){
      Vec3 e = pos[i+1][j].minus(pos[i][j]);
      float currentLen = e.length();
      e = e.normalized();
      float v1 = dot(e, vel[i][j]);
      float v2 = dot(e, vel[i+1][j]);
      float stringF = -k*(currentLen-restLen);
      float dampF = -kv*(v2-v1);
      Vec3 force = e.times(stringF+dampF);
      acc[i][j].add(force.times(-1.0/mass));
      acc[i+1][j].add(force.times(1.0/mass));
    }
  }
  
  //the first row doesn't move
  for(int i = 0; i < numNodes; i++) {
    vel[i][0] = new Vec3(0,0,0);
  }
  
  //collision handling and update all positions and velocities
  for (int i = 0; i < numNodes; i++){
    for(int j = 1; j < numNodes; j++){
      float l = spherePos.distanceTo(pos[i][j]);
      if(l < obstacleSphere + radius + 0.09) {
         System.out.println("true");
         Vec3 n = pos[i][j].minus(spherePos);
         n = n.normalized();
         float v = dot(vel[i][j], n);
         Vec3 bounce = n.times(v);
         vel[i][j].subtract(bounce.times(1.1));
         pos[i][j].add(n.times(0.1+obstacleSphere + radius-l));
      }
      vel[i][j].add(acc[i][j].times(dt)); //update velocity
      pos[i][j].add(vel[i][j].times(dt)); //update position
      
      if(vel[i][j] == null) {
         paused = true;
      }
    }
  }
}

//Draw the scene: one sphere per mass, one line connecting each pair
boolean paused = true;
void draw() {
  background(0);
  lights();
  for(int i = 0; i < 120; i++) {
     camera.Update(1.0/(20 * frameRate));
  }
 
  if (!paused) {
    for(int i = 0; i < 120; i++) {
      update(1/(20 * frameRate)); 
    }
  }
  
  //add texture
  for (int j = 0; j < numNodes-1; j++){
    for(int i = 0; i < numNodes-1; i++){
      beginShape();
      texture(img);
      vertex(pos[i][j].x,pos[i][j].y, pos[i][j].z, ((float)i/(numNodes-1))*img.width,((float)j/(numNodes-1))*img.height);
      vertex(pos[i+1][j].x,pos[i+1][j].y, pos[i+1][j].z, ((float)(i+1)/(numNodes-1))*img.width,((float)j/(numNodes-1))*img.height);
      vertex(pos[i+1][j+1].x,pos[i+1][j+1].y, pos[i+1][j+1].z, ((float)(i+1)/(numNodes-1))*img.width,((float)(j+1)/(numNodes-1))*img.height);
      vertex(pos[i][j+1].x,pos[i][j+1].y, pos[i][j+1].z, ((float)i/(numNodes-1))*img.width,((float)(j+1)/(numNodes-1))*img.height);
      endShape();
    }
  }
  
  //debug mode to have balls and lines
  if(debug){
    for (int i = 0; i < numNodes; i++){
      for(int j = 0; j < numNodes; j++){
       pushMatrix();
       translate(pos[i][j].x,pos[i][j].y,pos[i][j].z);
       sphere(radius);
       popMatrix();
      }
    }

    for (int i = 0; i < numNodes; i++){ 
      for(int j = 0; j < numNodes-1; j++) {
       stroke(0,128,0);
       line(pos[i][j].x,pos[i][j].y,pos[i][j].z,pos[i][j+1].x,pos[i][j+1].y,pos[i][j+1].z);
      }
    }
    for (int i = 0; i < numNodes; i++){
      for(int j = 0; j < numNodes-1; j++) {
       stroke(0,128,0);
       line(pos[j][i].x,pos[j][i].y,pos[j][i].z,pos[j+1][i].x,pos[j+1][i].y,pos[j+1][i].z);
      }
    }
  }
  
  //draw the obstacle
  noStroke();
  fill(255);
  pushMatrix();
  translate(spherePos.x, spherePos.y, spherePos.z);
  sphere(obstacleSphere);
  popMatrix();
 
  if (paused)
    surface.setTitle(windowTitle + " [PAUSED]");
  else
    surface.setTitle(windowTitle + " "+ nf(frameRate,0,2) + "FPS");
}


void mousePressed(){
   if(mouseButton == LEFT)  //left click to start/pause the simulation
    paused = !paused;
   else if(mouseButton == RIGHT){  //right click to reset the simulation
     initScene();
     paused = true;
   }
}

void keyPressed()
{
  if(key == ' ') {  //press space to enable/disable debug mode
     debug = !debug;
  }
  camera.HandleKeyPressed();  //press keyboard to adjust camera
}

void keyReleased()
{
  camera.HandleKeyReleased();
}
