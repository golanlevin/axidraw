# Processing to AxiDraw v3
#### Controlling the AxiDraw v3 Plotter with Processing 3

- Tested with Processing v3.5 on OSX 10.14, with Node.js 15.14.0 and npm 7.7.6.
- Based on project by Aaron Koblin: https://github.com/koblin/AxiDrawProcessing
- Uses CNCServer by @techninja: https://github.com/techninja/cncserver



## Setup
> Note: Instructions are for Mac OS

1. Install and Update Hombrew (detailed instructions [here](http://blog.teamtreehouse.com/install-node-js-npm-mac)). Open Terminal and type:
```
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```
2. Update Homebrew (this could take a while):
```
brew update
```
3. Install Node.js:
```
brew install node
```
4. Clone or Download [CNCServer](https://github.com/techninja/cncserver):
```
git clone https://github.com/techninja/cncserver.git
```
5. Install NPM (Node Package Manager):
```
cd cncserver
npm install
```
6. Install [Processing](https://processing.org/download/)

7. Plug in the AxiDraw to your computer

8. Start the Node CNCServer to open communications with your AxiDraw. You should hear the motors click on after running this command:
```
sudo node cncserver --botType=axidraw
```
9. Run `AxiDraw_Mouse.pde` 

## Tips & Tricks

If not working:
- Verify you can control your machine through AxiDraw's [Inkscape plugin](https://wiki.evilmadscientist.com/Axidraw_Software_Installation).
- Verify you are running the `node cncserver` with `sudo`:
```
sudo node cncserver --botType=axidraw
```

## External Control & TouchOSC
This example shows you how to control the AxiDraw from external apps, phones, and tablets over [OSC](http://www.sojamo.de/libraries/oscP5/).

I control touch devices using [TouchOSC](https://hexler.net/touchosc). To use TouchOSC:
1. Download the app from your repsective app store.
2. Download the free [TouchOSC Editor](https://hexler.net/pub/touchosc/touchosc-editor-1.8.9-macos.zip)
3. In the editor, open the `touchosc_xy_pad.touchosc` file the Processing sketch's `/data` folder.
4. Sync from the Editor to your Device following [these](https://hexler.net/docs/touchosc-editor-sync) instructions.
5. Select the `touchosc_xy_pad` layout from your device's layout options.
6. Connect the Processing sketch to Touch OSC using [these](https://hexler.net/docs/touchosc-configuration-connections-osc) instructions.
    - The Processing sketch is listening on port `12000`. Be sure your TouchOSC outgoing port is set correctly.
