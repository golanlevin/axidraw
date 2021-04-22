import controlP5.*;

// Real-time AxiDraw Mouse-Following. 
// by Golan Levin, September 2018. 
//
// Known to work with Processing v3.4 on OSX 10.13.5, 
// Using Node.js v10.10.0, npm v6.4.1.
// Based on AxiDraw_Simple by Aaron Koblin
// https://github.com/koblin/AxiDrawProcessing
// Uses CNCServer by @techninja
// https://github.com/techninja/cncserver
//
// Instructions: in a terminal, type 
// node cncserver --botType=axidraw
// Then run this program. 


CNCServer cnc;
boolean bPlotterIsZeroed;
boolean bFollowingMouse;

ControlP5 cp5;
Accordion collapsable_frame;

void setup() {
  size(1000, 1000); 
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
}

//=======================================
void draw() {

  if (bPlotterIsZeroed) {
    background(255, 255, 255); 
    if (bFollowingMouse) {
      float mx = constrain(mouseX/10.0, 0, 100);
      float my = constrain(mouseY/10.0, 0, 100); 
      cnc.moveTo(mx, my);
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
}


//=======================================
void keyPressed() {

  if (key == 'u') {
    cnc.unlock();
    println("Pen unlocked ..... remember to zero!");
  }

  if (key == 'z') {
    cnc.zero();
    bPlotterIsZeroed = true; 
    println("Pen zero'd");
  }

  if (key == 'd') {
    bFollowingMouse = !bFollowingMouse;
    println("bFollowingMouse = " + bFollowingMouse);
  }
}


//=======================================
void setup_gui() {
  cp5 = new ControlP5(this);

  Group axi_controller = cp5.addGroup("AxiDraw Controller")
              .setPosition(10,10)
              .setWidth(200)
              .setBackgroundHeight(360)
              .setBackgroundColor(color(0,50))
              ;
   
  PVector p = new PVector(axi_controller.getPosition()[0], axi_controller.getPosition()[1]);
  p.x += 0;
  p.y += 0;
  int group_width = axi_controller.getWidth();
  int btn_width = 20;
  
  // Add the MOTOR Parameters
  cp5.addTextlabel("motor_params")
     .setText("MOTOR PARAMETERS")
     .setPosition(p.x-4,p.y)
     .setGroup(axi_controller)
     ;
  
  p.y += 15;
  
  cp5.addToggle("motor_state")
     .setLabel("MOTOR STATE")
     .setPosition(p.x, p.y)
     .setSize(btn_width,btn_width)
     .setGroup(axi_controller)
  ;
  
   p.y += btn_width + 25;
  
  // Add the PEN Parameters
  cp5.addTextlabel("pen_params")
     .setText("PEN PARAMETERS")
     .setPosition(p.x-4,p.y)
     .setGroup(axi_controller)
     ;
  
  p.y += 15;
  
  cp5.addToggle("pen_state")
     .setLabel("PEN DOWN")
     .setPosition(p.x, p.y)
     .setSize(35,35)
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
     .setSize(group_width - 100,15)
     .setGroup(axi_controller)
     ;
  
  p.y += 35 + 25;
  
  // Add the HOMING Parameters
  cp5.addTextlabel("homing_params")
     .setText("HOMING PARAMETERS")
     .setPosition(p.x-4,p.y)
     .setGroup(axi_controller)
     ;
  
  p.y += 15;
  
  cp5.addBang("set_home")
     .setLabel("SET HOME")
     .setValue(0)
     .setPosition(p.x,p.y)
     .setSize(btn_width,btn_width)
     .setGroup(axi_controller)
     ;
   
  cp5.addBang("go_home")
     .setLabel("GO HOME")
     .setValue(0)
     .setPosition(p.x + 2.5*btn_width,p.y)
     .setSize(btn_width,btn_width)
     .setGroup(axi_controller)
     ;
     
p.y += btn_width + 25;
  
  // Add the PREVIEW Canvas 
  // (shown as a percentage of travel area)
  cp5.addTextlabel("preview")
     .setText("POSITION PREVIEW")
     .setPosition(p.x-4,p.y)
     .setGroup(axi_controller)
     ;
  
  p.y += 15;
  float w = group_width - 20;
  float h = w * .6470;
  cp5.addSlider2D("axi_preview")
         .setPosition(p.x,p.y)
         .setSize(int(w),int(h))
         .setMinMax(0,0,100,100)
         .setValue(50,50)
         .setGroup(axi_controller)
         ;
  p.y += h;
  
 
  
  // Add different groups to a collapsable frame
  collapsable_frame = cp5.addAccordion("acc")
                 .setPosition(axi_controller.getPosition())
                 .setWidth(axi_controller.getWidth())
                 .addItem(axi_controller)
                 ;
  collapsable_frame.open(0);                 
  collapsable_frame.setCollapseMode(Accordion.MULTI);         
}

//=======================================
void controlEvent(ControlEvent theEvent) {
  if(theEvent.isGroup()) {
    println("got an event from group "
            +theEvent.getGroup().getName()
            +", isOpen? "+theEvent.getGroup().isOpen()
            );
            
  } else if (theEvent.isController()){
    println("got something from a controller "
            +theEvent.getController().getName()
            );
  }
}


//=======================================
void exit() {
  cnc.penUp();
  cnc.unlock();
  println("Goodbye!");
  super.exit();
}

void stop() {
  super.exit();
}
