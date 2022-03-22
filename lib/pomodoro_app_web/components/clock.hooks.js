let Clock = {
  mounted(){
    console.log("Clock mounted")
    currentTime()
  },

  destroyed() {
    console.log("Clock destroyed")
    clearTimeout(this.pid);
  }
};

function currentTime() {
  var date = new Date();
  var hour = date.getHours() % 12;
  var min = date.getMinutes();
  var amPM = date.getHours() >= 12 ? "PM" : "AM";
  hour = updateTime(hour);
  min = updateTime(min);
  document.getElementById('clock').innerText = hour + " : " + min + " " + amPM;
  this.pid = setTimeout(function(){ currentTime() }, 1000);
}

function updateTime(k) {
  if (k < 10) {
    return "0" + k;
  }
  else {
    return k;
  }
}

export { Clock }
