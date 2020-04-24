const cp = require('child_process')
exports.prepareReport = function() {
    // cp.exec("chmod", "chmod 744 formatReport.sh", function (error, stdout, stderr) {
    //     console.log('stdout: ' + stdout);
    //     console.log('stderr: ' + stderr);
    //     if (error !== null) {
    //       console.log('exec error: ' + error);
    //     } 
    // })

    cp.exec("formatReport", "./formatReport.sh", function (error, stdout, stderr) {
        console.log('stdout: ' + stdout);
        console.log('stderr: ' + stderr);
        if (error !== null) {
          console.log('exec error: ' + error);
        } 
    })
}