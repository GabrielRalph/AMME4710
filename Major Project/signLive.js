import {SvgPlus} from "../SvgPlus/4.js"

async function delay(x) {
  return new Promise((resolve, reject) => {
    setTimeout(() => resolve(), x);
  });
}
const LETTERS = " ABCDEFGHIJKLMNOPQRSTUVWXYZ";
class SignLive extends SvgPlus {
  constructor(el){
    super(el);
    console.log('x');
    this.ondblclick = () => {
      console.log('yyy');
      this.stopDetection()
    }
  }

  onconnect(){
    console.log('xxx');
    this.innerHTML = `<video autoplay="true"></video>`;
    this.video = this.querySelector("video");
    this.words = this.createChild("div", {class: "words"});
    console.log();
    this.startWebCam();

    // this.addLetter("a")

    this.startDetection();
  }

  async startWebCam(){
    let {video} = this;
    if (navigator.mediaDevices.getUserMedia) {

      let stream = await navigator.mediaDevices.getUserMedia({ video: true });
      
      video.srcObject = stream;
    }
  }

  getInputFrame(){
    let image = null;

    return image
  }

  async predictSignLetter(image) {
    let letter = " ";
    let conf = 0.95;

    if (Math.random() < 0.7) {
      let i = Math.round(26 * Math.random());
      letter = LETTERS[i];
    }

    await delay(Math.random() * 600 + 200);

    return [letter, conf];
  }



  async startDetection(){
    // this.startWebCam();
    let stop = false;
    this.stopDetection = () => {stop = true;}
    while (!stop) {
      let image = this.getInputFrame();

      let [letter, conf] = await this.predictSignLetter();
      console.log(`${letter} (${conf})`);
      this.addLetter(letter);
    }
  }

  stopDetection(){}



  addLetter(letter) {
    this.words.innerHTML += letter;
  }

  clearWord(){}
}

SvgPlus.defineHTMLElement(SignLive);
