import {SvgPlus, Vector} from "../../SvgPlus/4.js"
async function delay(x) {
  return new Promise((resolve, reject) => {
    setTimeout(() => resolve(), x);
  });
}

const LETTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ "



class SignLive extends SvgPlus {
  constructor(el){
    super(el);
    this.ondblclick = () => {
      this.stopDetection()
    }
  }

  onconnect(){
    this.innerHTML = "";
    this.vBox = this.createChild("div", {style: {position: "relative"}});
    this.video = this.vBox.createChild("video", {autoplay: true});
    for (let cname of ["canvas", "canny", "incanv"]) {
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
    this.incanv.styles = {
      background: "white",
      "pointer-events": "none"
    }
    this.words = this.createChild("div", {class: "words"});
    this.load();
  }

  start_processing(){
    let {canny} = this;
    canny.onclick = (e) => {
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
    // setTimeout(() => {
    //   this.process_frame();
    // }, 5000)
  }

  onclick(){
    this.process_frame();
  }

  async process_frame(){
    this.capture_frame();
    this.apply_canny();
    this.prepare_input();
    await this.display_input();
    // await this.predict_letter();
  }
  capture_frame(){
    let {video, canvas} = this;
    canvas.width = video.offsetWidth;
    canvas.height = video.offsetHeight;

    let ctx = canvas.getContext('2d');
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height );
  }
  apply_canny(){
    let cv = window.cv;
    if (!(cv.Mat instanceof Function)) return;
    let {canny, canvas, th1, th2} = this;
    var src = cv.imread(canvas); // load the image from <img>
    var dst = new cv.Mat();

    cv.cvtColor(src, src, cv.COLOR_RGB2GRAY, 0);

    cv.Canny(src, dst, th1, th2, 3, false); // You can try more different parameters
    cv.imshow(canny, dst); // display the output to canvas

    this.inputData = dst;

    src.delete(); // remember to free the memory
  }
  async display_input(){
    let {incanv, input} = this;
    incanv.width = 513;
    incanv.height = 512;
    let resize = input.reshape([512*513*3]);
    let arr = await resize.array();
    resize.dispose();
    console.log(arr);
    let ctx = incanv.getContext('2d');
    let imdata = ctx.createImageData(512, 513);
    for (let i = 0; i < 512 * 513; i++) {
      imdata.data[4 * i] = arr[i * 3] * 255;
      imdata.data[4 * i + 1] = arr[i * 3 + 1] * 255;
      imdata.data[4 * i + 2] = arr[i * 3 + 2] * 255;
      imdata.data[4 * i + 3] = arr[i * 3 + 3] * 255;
    }
    ctx.putImageData(imdata, 0, 0);
  }
  prepare_input(){
    let {tf} = window;
    let irows = 512;
    let icols = 513;

    let {canny, inputData, model} = this;
    if (tf && inputData) {
      let {rows, cols, data} = inputData;
      let mat1d = tf.tensor1d(data);
      console.log("MAT 1D");
      mat1d.sum().print()

      let mat1dn = mat1d.div(255);
      mat1d.dispose();

      let mat4d = mat1dn.reshape([1, rows, cols, 1]);
      console.log("MAT 4D");
      mat4d.sum().print();
      mat1dn.dispose();

      let min = rows < cols ? rows : cols;
      let rowstart = rows < cols ? 0 : Math.round((rows - cols) / 2);
      let colstart = cols < rows ? 0 : Math.round((cols - rows) / 2);
      let mat4dq = mat4d.slice([0, rowstart, colstart, 0], [1, min, min, 1]);
      console.log("MAT 4D Square");
      mat4dq.sum().print();
      mat4d.dispose();

      let in4d = tf.image.resizeNearestNeighbor(mat4dq, [irows, icols]);
      console.log("input 4D (1 x 512 x 513 x 1)");
      in4d.sum().print();
      mat4dq.dispose();

      let in4d3 = in4d.concat(in4d, 3).concat(in4d, 3);
      console.log("input 4D (1 x 512 x 513 x 3)");
      in4d3.sum().print();
      in4d.dispose();

      this.input = in4d3;
    }
    inputData.delete();
  }
  async predict_letter(){
    console.log(this.model);
    if (this.model) {
      console.log("here");
      this.input.sum().print();
      let y = this.model.predict(this.input);
      console.log(await this.input.array());
      let data = (await y.array())[0];
      y.dispose();
      let str = "";
      let maxConf = 0;
      let bestGuess = 0;
      for (let i = 0; i < data.length; i++) {
        let v = (new Vector(data[i])).round(5)
        let conf = v.x;
        str += `${LETTERS[i]}: ${1 - conf}\n`;
        if (conf > maxConf) {
          maxConf = conf;
          bestGuess = LETTERS[i];
        }
      }
      console.log(str);
      this.words.innerHTML = bestGuess;
    }
    this.input.dispose();
  }

  async load_opencv(){}
  async start_webcam(){
    let {video} = this;
    let stream = await navigator.mediaDevices.getUserMedia({ video: true });
    video.srcObject = stream;
  }
  async load_model(){
    let {tf} = window;
    this.model = await tf.loadLayersModel(this.getAttribute("src"));
    console.log(this.model);
  }

  async load(){
    try{
      await this.start_webcam();
    } catch(e) {
      throw e;
    }

    try {
      this.load_opencv()
    } catch (e) {
      throw e;
    }

    try {
      this.load_model();
    } catch(e) {
      console.log(e);
    }

    this.start_processing();
  }

}

SvgPlus.defineHTMLElement(SignLive);
