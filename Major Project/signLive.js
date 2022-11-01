import {SvgPlus, Vector} from "../SvgPlus/4.js"

async function delay(x) {
  return new Promise((resolve, reject) => {
    setTimeout(() => resolve(), x);
  });
}


const LETTERS = " ABCDEFGHIJKLMNOPQRSTUVWXYZ";
class SignLive extends SvgPlus {
  constructor(el){
    super(el);
    this.ondblclick = () => {
      this.stopDetection()
    }
  }

  onconnect(){
    console.log('xxx');
    this.innerHTML = "";

    this.vBox = this.createChild("div", {style: {position: "relative"}});
    this.video = this.vBox.createChild("video", {autoplay: true});
    for (let cname of ["canvas", "canny"]) {
      this[cname] = this.vBox.createChild("canvas", {
        style: {
          "position": "absolute",
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
        }
      });
    }
    this.words = this.createChild("div", {class: "words"});

    this.startWebCam();

    // this.startDetection();
  }


  capture_frame(){
    let {video, canvas} = this;
    canvas.width = video.offsetWidth;
    canvas.height = video.offsetHeight;

    let ctx = canvas.getContext('2d');
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height );

    let image = canvas.toDataURL('image/jpeg');
  }
  apply_canny(){
    let {canny, canvas, th1, th2} = this;
    var src = cv.imread(canvas); // load the image from <img>
    var dst = new cv.Mat();

    cv.cvtColor(src, src, cv.COLOR_RGB2GRAY, 0);

    cv.Canny(src, dst, th1, th2, 3, false); // You can try more different parameters
    cv.imshow(canny, dst); // display the output to canvas

    src.delete(); // remember to free the memory
    dst.delete();
  }
  start_testing(){
    let {canny} = this;
    canny.onmousemove = (e) => {
      let v = new Vector(e.x, e.y);
      let [pos, size] = this.video.bbox;
      let vnorm = v.sub(pos).div(size);
      let thv = vnorm.mul(300).add(5).round(2);

      this.th1 = thv.x;
      this.th2 = thv.y;
      this.words.innerHTML = `th1: ${this.th1}<br />sth2: ${this.th2}`
    }
    this.th1 = 50;
    this.th2 = 50;
    setInterval(() => {
      this.capture_frame();
      this.apply_canny();
    }, 50)
  }


  async startWebCam(){
    let {video} = this;
    if (navigator.mediaDevices.getUserMedia) {
      let stream = await navigator.mediaDevices.getUserMedia({ video: true });
      video.srcObject = stream;
      this.start_testing();

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


  // async startDetection(){
  //   // this.startWebCam();
  //   let stop = false;
  //   this.stopDetection = () => {stop = true;}
  //   while (!stop) {
  //     let image = this.getInputFrame();
  //
  //     let [letter, conf] = await this.predictSignLetter();
  //     // console.log(`${letter} (${conf})`);
  //     this.addLetter(letter);
  //   }
  // }
  //
  // stopDetection(){}


  addLetter(letter) {
    let text = this.words.innerHTML + letter;
    if (text.length > 20) {
      text = text.slice(1);
    }
    this.words.innerHTML = text;

  }

  clearWord(){}
}

SvgPlus.defineHTMLElement(SignLive);
