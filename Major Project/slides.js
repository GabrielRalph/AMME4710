let n = document.querySelectorAll("p-slide").length;
let slide = 0;
function gotoSlide(x){
  if (x < 0) x = 0;
  if (x >= n) x = n - 1;
  let sh = window.innerHeight;
  slide = x;
  window.scrollTo(0, sh * slide);
  console.log(sh * slide);
}

gotoSlide(0);
window.onkeyup = (e) => {
  switch (e.key) {
    case "ArrowUp": gotoSlide(slide - 1);break
    case "ArrowDown": gotoSlide(slide + 1);break
  }
}
window.ondblclick = (e) => {
  gotoSlide(slide + 1);
}
window.oncontextmenu = (e) => {
  gotoSlide(slide - 1);
  e.preventDefault();
}
