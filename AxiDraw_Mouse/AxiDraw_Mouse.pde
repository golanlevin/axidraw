import netP5.*;
import oscP5.*;

import controlP5.*;

// Real-time AxiDraw Mouse-Following. 
// by Golan Levin, September 2018.
// Revamped by Madeline Gannon, April 2021.
//
// Known to work with Processing v3.4 on OSX 10.13.5, 
// Using Node.js v10.10.0, npm v6.4.1.
// Based on AxiDraw_Simple by Aaron Koblin
// https://github.com/koblin/AxiDrawProcessing
// Uses CNCServer by @techninja
// https://github.com/techninja/cncserver
//
// Instructions: in a terminal, type 
// sudo node cncserver --botType=axidraw
// Then run this program. 


/**
 *  TO DO:
 *    - Fix mapping between mouseX/mouseY and travel width/height 
 *         (the AxiDraw is not moving its full range)
 *    - Add OSC panel
 */

OscP5 oscP5;
boolean remote_control = true;

CNCServer cnc;
boolean bPlotterIsZeroed;
boolean bFollowingMouse;

ControlP5 cp5;
Accordion collapsable_frame;
boolean show_gui = true;

PVector plotter_pt = new PVector();
PVector home_pos = new PVector(-1, -1);

enum Mode {
  NONE, 
    LIVE, 
    PLOT
} 
Mode drawing_mode = Mode.NONE;
boolean do_drawing = false;


void settings() {
  int w = 1000;
  float h = w * .6470; // aspect ratio of AxiDraw v3
  size(w, int(h));
}

void setup() {
  background(0, 0, 0); 
  fill(255, 255, 255); 
  text("Waiting for plotter to connect.", 20, 20); 

  setup_gui();

  bPlotterIsZeroed = false;
  bFollowingMouse = false;
  cnc = new CNCServer("http://localhost:4242");
  cnc.unlock();
  cnc.penUp();
  println("Plotter is at home? Press 'u' to unlock, 'z' to zero, 'd' to draw");
  
  if (remote_control){
      // start oscP5, listening for incoming messages at port 12000
      oscP5 = new OscP5(this,12000);

  }
}

void update() {
  println("yoooo");
}

//=======================================
void draw() {

  if (isHomePosSet()) {
    background(255, 255, 255); 
    //if (bFollowingMouse) {
    if (drawing_mode == Mode.LIVE && do_drawing) {

      // follow the mouse
      float x = map(mouseX, 0, width, 0, 100);
      float y = map(mouseY, 0, height, 0, 100);
      plotter_pt.x = constrain(x, 0, 100); 
      plotter_pt.y = constrain(y, 0, 100); 

      // update the axi_preview postion
      float temp [] = {plotter_pt.x, plotter_pt.y};
      cp5.getController("axi_preview").setArrayValue(temp);

      // make your move
      cnc.moveTo(plotter_pt.x, plotter_pt.y);

      // move the pen up & down
      if (mousePressed) {
        cnc.penDown();
      } else {
        cnc.penUp();
      }
    } else {
      fill(0, 0, 0);
      text ("Enable drawing to move plotter.", 20, 20);
      text ("Toggle 'd' to enable drawing.", 20, 35);
    }
  } else {
    background(255, 0, 0); 
    fill(255, 255, 255); 
    text("Must zero plotter before use!", 20, 20);
    text("Move plotter to home position, press 'z'.", 20, 35);
  }

  if (show_gui) {
    cp5.draw();
  }
}


//=======================================
void keyPressed() {

  // Unlock the Motors
  if (key == 'u') {
    cnc.unlock();
    home_pos.set(-1, -1);
    println("Motors unlocked — remember to re-home the AxiDraw!");
  }

  // Re-Home the AxiDraw
  if (key == 'z') {
    cnc.zero();
    home_pos.set(0, 0);
    bPlotterIsZeroed = true; 
    println("Pen zero'd");
  }
  
  // Send the AxiDraw Home
  if (key == 'g') go_home();

  // Change the drawing state
  if (key == 'd') {
    bFollowingMouse = !bFollowingMouse;
    do_drawing = !do_drawing;
    cp5.getController("do_drawing").setValue(do_drawing?1.0:0.0);
    
    // update the mode
    if (do_drawing && drawing_mode == Mode.NONE){
       drawing_mode = Mode.LIVE;   // go LIVE by default
    }
    println("bFollowingMouse = " + bFollowingMouse);
  }
  
  // Toggle the pen
  if (key == 'p') {
    float pen_state = cp5.getController("pen_state").getValue();
    cp5.getController("pen_state").setValue(abs(1-pen_state));
  }
  
  // Toogle the gui
  if (key == 'h') {
    show_gui = !show_gui;
  }
}

//=======================================
void go_home() {
  cnc.penUp();
  plotter_pt.set(0, 0);
  // update the axi_preview postion
  float temp [] = {plotter_pt.x, plotter_pt.y};
  cp5.getController("axi_preview").setArrayValue(temp);
  // go home
  cnc.moveTo(plotter_pt.x, plotter_pt.y);
}

//=======================================
boolean isHomePosSet() {
  return home_pos.x == 0 && home_pos.y==0;
}


//=======================================
void setup_gui() {
  cp5 = new ControlP5(this);
  cp5.setAutoDraw(false);

  Group axi_controller = cp5.addGroup("AxiDraw Controller")
    .setPosition(10, 10)
    .setWidth(200)
    .setBackgroundHeight(360)
    .setBackgroundColor(color(0, 50))
    ;

  PVector p = new PVector(axi_controller.getPosition()[0], axi_controller.getPosition()[1]);

  int group_width = axi_controller.getWidth();
  int btn_width = 20;

  // Add the MOTOR Parameters
  cp5.addTextlabel("motor_params")
    .setText("MOTOR PARAMETERS")
    .setPosition(p.x-4, p.y)
    .setGroup(axi_controller)
    ;

  p.y += 15;

  cp5.addBang("motor_state")
    .setLabel("MOTORS OFF")
    .setPosition(p.x, p.y)
    .setSize(btn_width, btn_width)
    .setGroup(axi_controller)
    ;

  p.y += btn_width + 25;

  // Add the PEN Parameters
  cp5.addTextlabel("pen_params")
    .setText("PEN PARAMETERS")
    .setPosition(p.x-4, p.y)
    .setGroup(axi_controller)
    ;

  p.y += 15;

  cp5.addToggle("pen_state")
    .setLabel("PEN DOWN")
    .setPosition(p.x, p.y)
    .setSize(35, 35)
    .setGroup(axi_controller)
    ;
  cp5.addSlider("pen_min")
    .setLabel("PEN MIN")
    .setValue(.25)
    .setMin(0)
    .setMax(1)
    .setPosition(p.x + 40, p.y)
    .setSize(group_width - 100, 15)
    .setGroup(axi_controller)
    ;
  cp5.addSlider("pen_max")
    .setLabel("PEN MAX")
    .setValue(.75)
    .setMin(0)
    .setMax(1)
    .setPosition(p.x + 40, p.y + 20)
    .setSize(group_width - 100, 15)
    .setGroup(axi_controller)
    ;

  p.y += 35 + 25;

  // Add the HOMING Parameters
  cp5.addTextlabel("homing_params")
    .setText("HOMING PARAMETERS")
    .setPosition(p.x-4, p.y)
    .setGroup(axi_controller)
    ;

  p.y += 15;

  cp5.addBang("set_home")
    .setLabel("SET HOME")
    .setValue(0)
    .setPosition(p.x, p.y)
    .setSize(btn_width, btn_width)
    .setGroup(axi_controller)
    ;

  cp5.addBang("go_home")
    .setLabel("GO HOME")
    .setValue(0)
    .setPosition(p.x + 2.5*btn_width, p.y)
    .setSize(btn_width, btn_width)
    .setGroup(axi_controller)
    ;

  p.y += btn_width + 25;

  // Add the PREVIEW Canvas 
  // (shown as a percentage of travel area)
  cp5.addTextlabel("preview")
    .setText("POSITION PREVIEW")
    .setPosition(p.x-4, p.y)
    .setGroup(axi_controller)
    ;

  p.y += 15;
  float w = group_width - 20;
  float h = w * .6470;
  cp5.addSlider2D("axi_preview")
    .setPosition(p.x, p.y)
    .setSize(int(w), int(h))
    .setMinMax(0, 0, 100, 100)
    .setValue(50, 50)
    .setGroup(axi_controller)
    ;
  p.y += h;


  Group drawing_controller = cp5.addGroup("Drawing Controller")
    .setPosition(10, 10)
    .setWidth(200)
    .setBackgroundHeight(135)
    .setBackgroundColor(color(0, 50))
    ;
  p.set(drawing_controller.getPosition()[0], drawing_controller.getPosition()[1]);
  
  cp5.addTextlabel("drawing_modes")
    .setText("DRAWING MODE")
    .setPosition(p.x-4, p.y)
    .setGroup(drawing_controller)
    ;

  p.y += 15;

  cp5.addRadioButton("drawing_mode")
    .setPosition(p.x, p.y)
    .setSize(btn_width, btn_width)
    .setItemsPerRow(2)
    .setSpacingColumn(30)
    .addItem("LIVE", 1)
    .addItem("PLOT", 2)
    .setGroup(drawing_controller)
    ;

  p.y += btn_width + 15;

  cp5.addTextlabel("drawing_params")
    .setText("DRAWING PARAMETERS")
    .setPosition(p.x-4, p.y)
    .setGroup(drawing_controller)
    ; 
  p.y += 15;
  cp5.addToggle("do_drawing")
    .setLabel("DO DRAWING")
    .setPosition(p.x, p.y)
    .setSize(35, 35)
    .setGroup(drawing_controller)
    ;
  //cp5.addSlider("drawing_speed")
  //  .setLabel("SPEED")
  //  .setValue(1)
  //  .setMin(0)
  //  .setMax(1)
  //  .setPosition(p.x + 40, p.y)
  //  .setSize(group_width - 100, 15)
  //  .setGroup(drawing_controller)
  //  ;


  // Add different groups to a collapsable frame
  collapsable_frame = cp5.addAccordion("acc")
    .setPosition(axi_controller.getPosition())
    .setWidth(axi_controller.getWidth())
    .addItem(axi_controller)
    .addItem(drawing_controller);
  ;
  collapsable_frame.open(0, 1);                 
  collapsable_frame.setCollapseMode(Accordion.MULTI);

  cp5.mapKeyFor(new ControlKey() {
    public void keyEvent() {
      collapsable_frame.open(0, 1);
    }
  }
  , 'o');
  cp5.mapKeyFor(new ControlKey() {
    public void keyEvent() {
      collapsable_frame.close(0, 1);
    }
  }
  , 'c');
}

//=======================================
void controlEvent(ControlEvent theEvent) {

  if (theEvent.isGroup()) {
    if (theEvent.getGroup().getName() == "drawing_mode") {
      boolean draw_live = boolean(int(theEvent.getGroup().getArrayValue()[0]));
      boolean draw_plot = boolean(int(theEvent.getGroup().getArrayValue()[1]));
      if (draw_live) drawing_mode = Mode.LIVE;
      else if (draw_plot) drawing_mode = Mode.PLOT;
      else { drawing_mode = Mode.NONE; do_drawing = false; }
    }
  } else {
    if (theEvent.getController().getName() == "motor_state") {
      cnc.unlock();
      home_pos.set(-1, -1);
      println("MOTORS ARE OFF. You can now manually move the carriage.");
      println("Remember to reset the Home Pos.\n");
    } else if (theEvent.getController().getName() == "pen_state") {
      println(theEvent.getController().getName()+": "+theEvent.getController().getValue());
      switch(int(theEvent.getController().getValue())) {
      case 0:
        cnc.penUp();
        break;
      case 1:
        cnc.penDown();
        break;
      }
    } else if (theEvent.getController().getName() == "pen_min") {
      println(theEvent.getController().getName()+": "+theEvent.getController().getValue());
      cnc.pen_dn_pos = map(theEvent.getController().getValue(), 0, 1, 1, 0);
    } else if (theEvent.getController().getName() == "pen_max") {
      println(theEvent.getController().getName()+": "+theEvent.getController().getValue());
      cnc.pen_up_pos = map(theEvent.getController().getValue(), 0, 1, 1, 0);
    } else if (theEvent.getController().getName() == "set_home") {
      cnc.zero();
      home_pos.set(0, 0);
      println("NEW HOME POSITION SET!");
    } else if (theEvent.getController().getName() == "go_home") {
      go_home();
    } else if (theEvent.getController().getName() == "axi_preview") {
      //println(theEvent.getController().getName()+": {"+theEvent.getController().getArrayValue()[0]+"," + theEvent.getController().getArrayValue()[1]+"}");
    } else if (theEvent.getController().getName() == "") {
      println(theEvent.getController().getName()+": "+theEvent.getController().getValue());
    } else {
      print("Unknown GUI Input from: ");
      //println(theEvent.getController().getName());
    }
  }
}


//=======================================
void exit() {
  go_home();
  cnc.unlock();
  println("Goodbye!");
  super.exit();
}

void stop() {
  super.exit();
}
