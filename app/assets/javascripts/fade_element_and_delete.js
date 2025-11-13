window.onload = fadeout;

async function fadeout() {
  const wait = (ms) => new Promise(resolve => setTimeout(resolve, ms));
  var fade = document.getElementById("flash_wrapper");
  await wait(2000)
  var intervalID = setInterval(function() {
    if (!fade.style.opacity) {
      fade.style.opacity = 1;
    }
    if (fade.style.opacity > 0) {
      fade.style.opacity -= 0.1;
    } else {
      clearInterval(intervalID);
    }
  }, 50);
}