# Processing to AxiDraw v3
#### Controlling the AxiDraw v3 Plotter with Processing 3

> Based on project by Aaron Koblin: https://github.com/koblin/AxiDrawProcessing


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


