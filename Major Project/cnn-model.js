let Model = null;

export async function load(){
  try {
    Model = await window.tf.loadLayersModel('./model.json');
  } catch (e) {
    console.log(e);
  }
}


export async function predict(canvas){
  return "A";
}
