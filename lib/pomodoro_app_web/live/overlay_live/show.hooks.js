export const Timer = {
  mounted(){
    console.log("Timer mounted")

    this.pid = setInterval(displayRemainingTime.bind(this), 1000);
  },

  destroyed(){
    console.log("Timer destroyed")
    clearInterval(this.pid);
  }
};


function displayRemainingTime() {
  const endTime = new Date(this.el.dataset.end);
  const currentTime = new Date();

  const timeRemaining = endTime.getTime() - currentTime.getTime();

  if (timeRemaining < 0) {
    clearInterval(this.pid);
    this.el.innerHTML = "00:00";
    return;
  }

  const formattedTimeRemaining = {
    minutes: padTime(Math.floor((timeRemaining / 1000) / 60)),
    seconds: padTime(Math.floor(timeRemaining / 1000 % 60))
  };

  this.el.innerText = `${formattedTimeRemaining.minutes}:${formattedTimeRemaining.seconds}`;
}

function padTime(k) {
  if (k < 10) {
    return "0" + k;
  }
  else {
    return k;
  }
}

