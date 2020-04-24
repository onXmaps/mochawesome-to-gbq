const cp = require('child_process')
exports.prepareReport = function() {
    cp.spawn('formatReport', ['./formatReport.sh'])
}