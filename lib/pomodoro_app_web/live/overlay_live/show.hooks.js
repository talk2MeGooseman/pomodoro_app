export const Timer = {
  mounted(){
    console.log("Timer mounted")

    this.pid = setInterval(displayRemainingTime.bind(this), 1000);
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

  const foramttedTimeRemaining = {
    minutes: Math.floor((timeRemaining / 1000) / 60),
    seconds: Math.floor(timeRemaining / 1000 % 60)
  };

  this.el.innerText = `${foramttedTimeRemaining.minutes}:${foramttedTimeRemaining.seconds}`;
}

