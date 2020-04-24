const cp = require('child_process')
exports.prepareReport = function() {
    cp.exec("../formatReport.sh", function (error, stdout, stderr) {
        console.log('stdout: ' + stdout);
        console.log('stderr: ' + stderr);
        if (error !== null) {
          console.log('exec error: ' + error);
        } 
    })
}