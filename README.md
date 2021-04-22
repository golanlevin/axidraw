# Processing to AxiDraw v3
#### Controlling the AxiDraw v3 Plotter with Processing 3

> Based on project by Aaron Koblin: https://github.com/koblin/AxiDrawProcessing


## Setup
> Note: Instructions are for Mac OS

1. Install and Update Hombrew (detailed instructions [here](http://blog.teamtreehouse.com/install-node-js-npm-mac)). Open Terminal and type:
```
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```
Update Homebrew:
```
brew update
```
2. Install Node.js:
```
brew install node
```
3. Clone or Download [CNCServer](https://github.com/techninja/cncserver):
```
git clone https://github.com/techninja/cncserver.git
```
4. Install NPM (Node Package Manager):
```
cd cncserver
npm install
```
5. Install [Processing](https://processing.org/download/)

6. Plug in the AxiDraw to your computer

7. Start the Node CNCServer to open communications with your AxiDraw
```
sudo node cncserver --botType=axidraw
```
8. Run `AxiDraw_Mouse.pde` 

## Tips & Tricks

If not working:
- Verify you can control your machine through AxiDraw's [Inkscape plugin](https://wiki.evilmadscientist.com/Axidraw_Software_Installation).
- Verify you are running the `node cncserver` with `sudo`:
```
sudo node cncserver --botType=axidraw
```


