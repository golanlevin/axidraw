import netP5.*;
import oscP5.*;
import controlP5.*;

import java.util.*;


// AxiDraw Plot Server Example
// by ATONATON
// @author Madeline Gannon, April 2021.
//
// Tested on Processing v3.5.4 on OSX 10.14.6, 
// Using Node.js v10.10.0, npm v6.4.1.
// Based on AxiDraw_Simple by Aaron Koblin
// https://github.com/koblin/AxiDrawProcessing
// Uses CNCServer by @techninja
// https://github.com/techninja/cncserver
//
// Instructions: in a terminal, type 
// sudo node cncserver --botType=axidraw_v3a3
// Then run this program. 


// AxiDraw connection
CNCServer cnc;

// OSC External Comms
OscP5 oscP5;
boolean remote_control = true;
int PORT_RECEIVING = 12000;

// GUI
ControlP5 cp5;
Accordion collapsable_frame;
boolean show_gui = true;

PVector plotter_pt = new PVector();
PVector home_pos = new PVector(-1, -1);

// App states
enum Mode {
  NONE, 
    LIVE, 
    PLOT
} 
Mode drawing_mode = Mode.NONE;
boolean do_drawing = false;

// Holds user drawn lines
ArrayList<ArrayList<PVector>> polylines = new ArrayList<ArrayList<PVector>>();

// Holds the list of lines to plot
Deque<ArrayList<PVector>> plot_queue = new  ArrayDeque<ArrayList<PVector>>();
// Shows which lines have been plotted
ArrayList<ArrayList<PVector>> drawn_lines = new ArrayList<ArrayList<PVector>>();


void settings() {
  int w = 1000;
  // set window to aspect ratio of AxiDraw v3
  float h = w * .6470; 
  size(w, int(h));
}

void setup() {
  background(0, 0, 0); 

  setup_gui();

  if (remote_control) setup_comms();

  setup_cnc_server();    // <-- should be in its own thread

  setup_geometry();
}

//=======================================
void draw() {

  if (!isHomePosSet()) {
    // Let the user know they need to HOME the machine
    background(242, 95, 95); 
    fill(255, 255, 255);
    textSize(14);
    textAlign(CENTER, CENTER);
    text("You must set a HOME POSITION before use.", width/2, height/2-25);
    text("1. TURN OFF the motors, \n2. Move the carriage to the TOP LEFT corner, \n3. Press 'z' to set the HOME POS.", width/2, height/2+25);
  } else {
    background(255, 255, 255); 

    // small demo for live control
    if (drawing_mode == Mode.LIVE && do_drawing) {      
      follow_mouse();
    } 

    // small demo for drawing/plotting with the mouse
    if (drawing_mode == Mode.PLOT) {      
      draw_user_polylines();
    } 
 
    draw_plot_lines(drawn_lines);
  }

  if (show_gui) {
    cp5.draw();
  }
}

//=======================================
void mousePressed() {
  if (!cp5.isMouseOver() && drawing_mode == Mode.PLOT) {
    polylines.get(polylines.size()-1).add(new PVector(mouseX, mouseY));
    plot_queue.getLast().add(new PVector(mouseX, mouseY));
  }
}

//=======================================
void mouseDragged() {
  if (!cp5.isMouseOver() && drawing_mode == Mode.PLOT) {
    float thresh = 5;
    PVector prev_pt = polylines.get(polylines.size()-1).get(polylines.get(polylines.size()-1).size()-1);
    PVector pt = new PVector(mouseX, mouseY);
    if (dist(prev_pt.x, prev_pt.y, pt.x, pt.y) > thresh) {
      polylines.get(polylines.size()-1).add(pt);
      plot_queue.getLast().add(pt);
    }
  }
}

//=======================================
void mouseReleased() {
  if (!cp5.isMouseOver() && drawing_mode == Mode.PLOT) {
    polylines.add(new ArrayList<PVector>());
    plot_queue.add(new ArrayList<PVector>());
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
    reset_home();
  }

  // Send the AxiDraw Home
  if (key == 'g') go_home();

  // Change the drawing state
  if (key == 'd') {
    do_drawing = !do_drawing;
    cp5.getController("do_drawing").setValue(do_drawing?1.0:0.0);

    // update the mode
    if (do_drawing && drawing_mode == Mode.NONE) {
      /// go LIVE by default and update trhought the GUI
      float [] temp = {1., 0};
      cp5.getGroup("drawing_mode").setArrayValue(temp);
    }
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

  // clear any user generated lines
  if (key == 'c') {
    polylines.clear();
    polylines.add(new ArrayList<PVector>());

    drawn_lines.clear();
    plot_queue.clear();
    plot_queue.add(new ArrayList<PVector>());
  }
}

//=======================================
void exit() {
  go_home();
  cnc.unlock();
  println("Goodbye!");
  super.exit();
}

//=======================================
void stop() {
  super.exit();
}

//=======================================
void follow_mouse() {
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
}

//=======================================
void move_to(PVector p) {
  // map the incoming point to the canvas dimensions
  float x = map(p.x, 0, width, 0, 100);
  float y = map(p.y, 0, height, 0, 100);
  plotter_pt.x = constrain(x, 0, 100); 
  plotter_pt.y = constrain(y, 0, 100); 

  // update the axi_preview postion
  float temp [] = {plotter_pt.x, plotter_pt.y};
  cp5.getController("axi_preview").setArrayValue(temp);

  // make your move
  cnc.moveTo(plotter_pt.x, plotter_pt.y);
}


//=======================================
void reset_home() {
  cnc.zero();
  home_pos.set(0, 0);

  // set the user-defined pen positions
  cnc.pen_up_pos = map(cp5.getController("pen_max").getValue(), 0, 1, 1, 0);
  cnc.pen_dn_pos = map(cp5.getController("pen_min").getValue(), 0, 1, 1, 0);

  println("HOME POS RESET");
}

//=======================================
void go_home() {
  // raise the pen all the way
  cnc.pen_up_pos = 0;
  cnc.penUp();
  plotter_pt.set(0, 0);
  // update the axi_preview postion
  float temp [] = {plotter_pt.x, plotter_pt.y};
  cp5.getController("axi_preview").setArrayValue(temp);
  // go home
  cnc.moveTo(plotter_pt.x, plotter_pt.y);
  // move the pen back to the user-defined UP pos
  cnc.pen_up_pos = map(cp5.getController("pen_max").getValue(), 0, 1, 1, 0);
  cnc.penUp();
}

//=======================================
boolean isHomePosSet() {
  return home_pos.x == 0 && home_pos.y==0;
}

//=======================================
void draw_user_polylines() {
  pushStyle();
  noFill();
  strokeWeight(12.0);
  strokeCap(ROUND);
  stroke(255, 0, 255, 120);
  // draw a FAT line
  for (ArrayList<PVector> line : polylines) {
    beginShape();
    for (PVector v : line) {
      vertex(v.x, v.y);
    }
    endShape();
  }
  noFill();
  strokeWeight(1.0);
  stroke(255, 0, 255);
  // draw a THIN line on top
  for (ArrayList<PVector> line : polylines) {
    beginShape();
    for (PVector v : line) {
      vertex(v.x, v.y);
    }
    endShape();
  }
  popStyle();
}

//=======================================
void plot(Deque<ArrayList<PVector>> lines) {
  while (lines.size() > 0) {
    // Add a new empty drawn line
    drawn_lines.add(new ArrayList<PVector>());
    // Plot the line
    plot_line(lines.poll());
  }
  // if we're done plotting, add an empty list to the queue
  plot_queue.add(new ArrayList<PVector>());
}

//=======================================
void plot_line(ArrayList<PVector> line) {
  // if we have points in the line
  if (line.size() > 0) {
    // move to the starting point
    move_to(line.get(0));
    println("PEN DOWN");
    cnc.penDown();
    // draw the line
    for (int i=0; i<line.size(); i++) {
      println(i+ ": " + line.get(i));
      move_to(line.get(i));
      // add to the drawn points for visualizing
      drawn_lines.get(drawn_lines.size()-1).add(line.get(i));
    }
    // retract the pen
    println("PEN UP");
    cnc.penUp();
  }
}

//=======================================
void draw_plot_lines(ArrayList<ArrayList<PVector>> lines) {
  pushStyle();
  noFill();
  strokeWeight(2);
  strokeCap(ROUND);

  int i=0;
  for (ArrayList<PVector> line : lines) {

    if (line.size() > 0) {

      // draw the travel line
      if (i!=0) {
        stroke(255, 0, 0);  // RED
        PVector prev_pt = polylines.get(i-1).get(polylines.get(i-1).size()-1);
        PVector pt = line.get(0);
        line(prev_pt.x, prev_pt.y, pt.x, pt.y);
      }
      // draw the plotted line
      stroke(36, 198, 255);  // BLUE
      beginShape();
      for (PVector v : line) {
        vertex(v.x, v.y);
      }
      endShape();

      i++;
    }
  }
  popStyle();
}

//=======================================
void setup_geometry() {
  // add the fist array list for mouse points to be added
  polylines.add(new ArrayList<PVector>());
  plot_queue.add(new ArrayList<PVector>());
}

//=======================================
void setup_comms() {
  // start oscP5, listening for incoming messages at port 12000
  oscP5 = new OscP5(this, PORT_RECEIVING);
}

//=======================================
void setup_cnc_server() {
  // TODO: should be in its own thread
  cnc = new CNCServer("http://localhost:4242");
  cnc.pen_up_pos = map(cp5.getController("pen_max").getValue(), 0, 1, 1, 0);
  cnc.pen_dn_pos = map(cp5.getController("pen_min").getValue(), 0, 1, 1, 0);
  cnc.unlock();
  cnc.penUp();
  println("AxiDraw is all set up! Remember to set the HOME POSITION :)");
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
  cp5.addBang("do_drawing")
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
  //cp5.mapKeyFor(new ControlKey() {
  //  public void keyEvent() {
  //    collapsable_frame.close(0, 1);
  //  }
  //}
  //, 'c');
}

//=======================================
void controlEvent(ControlEvent theEvent) {

  if (theEvent.isGroup()) {
    if (theEvent.getGroup().getName() == "drawing_mode") {
      boolean draw_live = boolean(int(theEvent.getGroup().getArrayValue()[0]));
      boolean draw_plot = boolean(int(theEvent.getGroup().getArrayValue()[1]));
      if (draw_live) drawing_mode = Mode.LIVE;
      else if (draw_plot) drawing_mode = Mode.PLOT;
      else { 
        drawing_mode = Mode.NONE; 
        do_drawing = false;
      }
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
      // update the axi_preview postion
      float temp [] = {0, 0};
      cp5.getController("axi_preview").setArrayValue(temp);
      println("NEW HOME POSITION SET!");
    } else if (theEvent.getController().getName() == "go_home") {
      go_home();
    } else if (theEvent.getController().getName() == "axi_preview") {
      //println(theEvent.getController().getName()+": {"+theEvent.getController().getArrayValue()[0]+"," + theEvent.getController().getArrayValue()[1]+"}");
    } else if (theEvent.getController().getName() == "do_drawing") {
      if (theEvent.getController().getValue()==1 && drawing_mode == Mode.PLOT) {
        println("Sending to PLOT");
        plot(plot_queue);
      }
    } else {
      print("Unknown GUI Input from: ");
      println(theEvent.getController().getName());
    }
    //else if (theEvent.getController().getName() == "") {
    //  println(theEvent.getController().getName()+": "+theEvent.getController().getValue());
    //}
  }
}

//=======================================
void oscEvent(OscMessage theOscMessage) {
  /* check if theOscMessage has the address pattern we are looking for. */

  if (theOscMessage.checkAddrPattern("/test")==true) {
    /* check if the typetag is the right one. */
    if (theOscMessage.checkTypetag("ifs")) {
      /* parse theOscMessage and extract the values from the osc message arguments. */
      int firstValue = theOscMessage.get(0).intValue();  
      float secondValue = theOscMessage.get(1).floatValue();
      String thirdValue = theOscMessage.get(2).stringValue();
      print("### received an osc message /test with typetag ifs.");
      println(" values: "+firstValue+", "+secondValue+", "+thirdValue);
      return;
    }
  }
  if (theOscMessage.checkAddrPattern("/point")==true) {
    if (theOscMessage.checkTypetag("ff")) {
      // update the target plotter point with the incoming pos     
      float x = map(theOscMessage.get(0).floatValue(), 0, width, 0, 100);
      float y = map(theOscMessage.get(1).floatValue(), 0, height, 0, 100);
      plotter_pt.x = constrain(x, 0, 100); 
      plotter_pt.y = constrain(y, 0, 100);

      move_to(plotter_pt);
    }
  } 
  println("### received an osc message. with address pattern "+theOscMessage.addrPattern());
}
