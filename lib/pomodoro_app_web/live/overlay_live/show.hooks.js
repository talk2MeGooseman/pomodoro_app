export const Timer = {
  mounted() {
    this.pid = setInterval(displayRemainingTime.bind(this), 1000);

    window.addEventListener('phx:pomo_end', onPomoEnd.bind(this))
  },

  destroyed() {
    clearInterval(this.pid);
    window.removeEventListener('phx:pomo_end', onPomoEnd.bind(this))
  }
};

function onPomoEnd(e) {
  const audio = new Audio("https://www.myinstants.com/media/sounds/star-trek-opening_8Ffzmjq.mp3");
  audio.play();
}


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

