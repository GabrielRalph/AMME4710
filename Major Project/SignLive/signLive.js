import {SvgPlus, Vector} from "../../SvgPlus/4.js"
async function delay(x) {
  return new Promise((resolve, reject) => {
    setTimeout(() => resolve(), x);
  });
}

const LETTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ "

function tic(){
  let start = performance.now();
  let toc = () => {return performance.now() - start;}
  return toc;
}


function cannyEdgeDetection(canvasInput, canvasOutput, th1, th2) {
  let cv = window.cv;
  let cannyOutput = null;

  try {
    let src = cv.imread(canvasInput); // load the image from <img>
    cannyOutput = new cv.Mat();

    cv.cvtColor(src, src, cv.COLOR_RGB2GRAY, 0);

    cv.Canny(src, cannyOutput, th1, th2, 3, false); // You can try more different parameters
    cv.imshow(canvasOutput, cannyOutput); // display the output to canvas

    src.delete(); // remember to free the memory
  } catch (e) {
    cannyOutput = null;
  }

  return cannyOutput;
}

function cropAndResizeCanny(cannyOutput, height, width, channels) {
  let {tf} = window;
  let irows = height;
  let icols = width;
  let croppedAndResized = null;
  let pos = null;
  if (tf && cannyOutput) {
    let {rows, cols, data} = cannyOutput;
    let mat1d = tf.tensor1d(data);
    let mat4d = mat1d.reshape([rows, cols, channels]);
    mat1d.dispose();

    let min = rows < cols ? rows : cols;
    let rowstart = rows < cols ? 0 : Math.round((rows - cols) / 2);
    let colstart = cols < rows ? 0 : Math.round((cols - rows) / 2);
    pos = [rowstart, colstart, min, min];
    let cropped = mat4d.slice([rowstart, colstart, 0], [min, min, channels]);
    mat4d.dispose();

    croppedAndResized = tf.image.resizeNearestNeighbor(cropped, [irows, icols]);
    cropped.dispose();
  }

  return [croppedAndResized, pos];
}

async function getModelPrediction(model, input){
  let y = model.predict(input);
  let data = (await y.array())[0];
  y.dispose();

  return data;
}

function bestLetter(guessConf){
  let maxConf = 0;
  let bestGuess = 0;
  for (let i = 0; i < guessConf.length; i++) {
    let conf = guessConf[i]
    if (conf > maxConf) {
      maxConf = conf;
      bestGuess = LETTERS[i];
    }
  }
  return bestGuess;
}

class SignLive extends SvgPlus {
  constructor(el){
    super(el);
    this._times = {};
    this.ondblclick = () => {
      this.log_time_stats();
    }
  }

  add_time(delta, name) {
    if (!(name in this._times)) {
      this._times[name] = [];
    }
    this._times[name].push(delta);
  }
  log_time_stats() {
    // console.log(`Time STATS for ${}`);
    let times = this._times;
    console.log(times);
    for (let name in times) {
      let data = times[name];
      let mean = 0;
      let std = 0;
      for (let time of data)
        mean += time;
      mean /= data.length;
      for (let time of data)
        std += Math.pow(time - mean, 2);
      std = Math.round(Math.sqrt(std / data.length));
      mean = Math.round(mean);
      console.log(`${name} took mean = ${mean}ms std = ${std} n = ${data.length}`)
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
    this.loader = this.vBox.createChild("div", {
      style: {
        "position": "absolute",
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        "--load": 0,
        "backdrop-filter": "blur(calc((1 - var(--load)) * 50px))",
        "-wibkit-backdrop-filter": "blur((1 - calc(var(--load)) * 50px))",
      }
    });
    this.text_center = this.vBox.createChild("div", {
      style: {
        "position": "absolute",
        top: "50%",
        left: "50%",
        transform: "translate(-50%, -50%)",
        "pointer-events": "none",

      }
    })
    this.text_corner = this.vBox.createChild("div", {
      style: {
        "position": "absolute",
        "pointer-events": "none",
        top: 0,
        left: 0,
        color: "blue",
        "font-size": "0.6em",
        "padding": "0.3em",
        background: "#fff5",
        "border-radius": "0 0 0.5em 0"
      }
    })

    this.th1 = 70;
    this.th2 = 80;
    this.loader.onclick = (e) => {
      let v = new Vector(e.x, e.y);
      let [pos, size] = this.loader.bbox;
      let vnorm = v.sub(pos).div(size);
      let thv = vnorm.mul(300).add(5).round(2);

      this.th1 = thv.x;
      this.th2 = thv.y;
      console.log('xx');
      this.text_corner.innerHTML = `th1: ${this.th1}<br />sth2: ${this.th2}`
    }

    this.words = this.createChild("div", {class: "words"});
    this.load();
  }

  async test_data(){
    let {tf} = window;
    let data = await fetch("./data.json");
    data = await data.json();
    let input = tf.tensor4d(data.input);
    this.input = input;
    this.predict_letter();
    await this.display_input();

  }
  async display_input(){
    let {incanv, input} = this;
    incanv.width = 513;
    incanv.height = 512;

    let arr = await input.array();
    let [batch, height, width, cdim] = input.shape;

    let ctx = incanv.getContext('2d');
    let imdata = ctx.createImageData(width, height);
    for (let i = 0; i < height; i++) {
      for (let j = 0; j < width; j++) {
        let pi0 = (i * width + j) * 4;
        let k = 0;
        for (k = 0; k < cdim; k++) {
          imdata.data[pi0 + k] = arr[0][i][j][k];
        }
        while (k < 4) {
          imdata.data[pi0 + k] = 255;
          k++;
        }
      }
    }

    ctx.putImageData(imdata, 0, 0);
  }


  start_processing(){
    console.log("processing");
    this.process_frames();
    this.predict_letters();
  }

  async process_frames(){
    while (!this.process_frames_stopped) {
      let time = 0;
      if (!document.hidden) {
        let toc = tic();
        this.capture_frame();
        time = toc();
        this.add_time(time, "capture frame");
      }
      this._last_toc = tic();
      if (time < 35) {
        await delay(35);
      }
    }
  }
  capture_frame(){
    let {tf} = window;
    let {video, canvas, canny, th1, th2} = this;


    canvas.width = video.offsetWidth;
    canvas.height = video.offsetHeight;

    let {width, height} = canvas;

    let toc = tic();
    let ctx = canvas.getContext('2d');
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
    this.add_time(toc(), "webcam capture");

    toc = tic();
    let input = cannyEdgeDetection(canvas, canny, th1, th2);
    this.add_time(toc(), "canny edge");

    if (this.input != null) {
      this.input.delete();
      this.input = null;
    }
    this.input = input;
  }

  async predict_letters(){
    while (!this.predict_letters_stopped) {
      let time = 0;
      if (!document.hidden) {
        if (this._last_toc) {
          this.add_time(this._last_toc(), "pfreq");
        }
        let toc = tic();
        await this.predict_letter();
        time = toc();
        this.add_time(time, "letter prediction")
      }

      if (time < 130) {
        await delay(130);
      }
    }
  }
  async predict_letter(){
    const height = 512;
    const width = 513;
    let {model, input, canny} = this;
    if (model && input) {
      this.input = null;

      let parsed = null
      let [cropped, pos] = cropAndResizeCanny(input, height, width, 1);
      input.delete();
      if (cropped) {

        let rgb = tf.image.grayscaleToRGB(cropped);
        cropped.dispose();

        parsed = rgb.reshape([1, height, width, 3]);
        rgb.dispose();
      }


      if (parsed) {
        let data = await getModelPrediction(model, parsed);
        parsed.dispose();

        let bestGuess = bestLetter(data);
        this.words.innerHTML = bestGuess;
      }
    }
  }


  async load_opencv(){}
  async start_webcam(){
    let {video} = this;
    let stream = await navigator.mediaDevices.getUserMedia({ video: true });
    video.srcObject = stream;
  }
  async load_model(){
    let {tf} = window;
    this.model = await tf.loadLayersModel(this.getAttribute("src"), {onProgress: (e) => {
      this.loader.styles = {
        "--load": e,
      }
      this.text_center.innerHTML = Math.round(e * 100) + "%";
      console.log(e);
    }});
    this.text_center.innerHTML = "";
    // await this.test_data();
    console.log("model loaded");
  }

  async load(){
    try{
      await this.start_webcam();
    } catch(e) {
      throw e;
    }

    try {
      await this.load_opencv()
    } catch (e) {
      throw e;
    }

    try {
      await this.load_model();
    } catch(e) {
      console.log(e);
    }

    this.start_processing();
  }

}

SvgPlus.defineHTMLElement(SignLive);
