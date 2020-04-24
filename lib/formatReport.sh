#!/bin/bash

echo "-- Running"
date=$(date +"%m-%d-%y:%H:%M:%S")
dataStore=$DS
tblFullReport=$TBLREPORT

echo -e "-- Generating reports\n"
npm run generate:reports
boolSkipping=false
flist=$(ls mochawesome-report/*.json | xargs -n 1 basename)
echo "mochawesome-report files: " $flist

mkdir -p mochawesome-report/backup

for f in $flist; do
   notSkip=$(grep -cim1 '"state": *"pending*"' mochawesome-report/$f)
   
   #If tests in spec file(s) are not skipped (state: pending), then proceed
   if (($notSkip == 0)); then
      echo "-- Processing file $f"
      
      # Get name of spec
      fname=$(grep -o '"fullFile": *"[^"]*"' mochawesome-report/$f | egrep -o "\w+.spec.js" | egrep -o "^\w+")
      
      echo "-- Backing up file $f"
      cp -- mochawesome-report/$f mochawesome-report/backup/$f
      
      echo "-- $f is backed up, removing duplicate"
      rm -f mochawesome-report/$f

      echo -e "-- Minifying file $f\n"
      node_modules/.bin/json-minify mochawesome-report/backup/$f > mochawesome-report/_$f
      
      isIntPassPercent=$(egrep -o -cim1 '"passPercent":[0-9]*,' mochawesome-report/_$f)
      isIntPendingPercent=$(egrep -o -cim1 '"pendingPercent":[0-9]*,' mochawesome-report/_$f)

      echo '-- Formatting new file to table schema specifications'
      echo "isIntPassPercent: " $isIntPassPercent
      echo "isIntPendingPercent: " $isIntPendingPercent
      if [ $isIntPassPercent == 1 ] && [ $isIntPendingPercent == 1 ]; then
         # format error and convert both percentages to floats
         sed -e "s/\"err\":{},/\"err\":{\"message\":\"\",\"estack\":\"\",\"diff\":null},/g" mochawesome-report/_$f | sed -e "s/\(\"passPercent\":[0-9]*\)/\1.00/g" | sed -e "s/\(\"pendingPercent\":[0-9]*\)/\1.00/g" > mochawesome-report/$f
      elif [ $isIntPassPercent == 0 ] && [ $isIntPendingPercent == 1 ]; then
         # format error and convert only pendingPercent
         sed -e "s/\"err\":{},/\"err\":{\"message\":\"\",\"estack\":\"\",\"diff\":null},/g" mochawesome-report/_$f | sed -e "s/\(\"pendingPercent\":[0-9]*\)/\1.00/g" > mochawesome-report/$f
      else
         sed -e "s/\"err\":{},/\"err\":{\"message\":\"\",\"estack\":\"\",\"diff\":null},/g" mochawesome-report/_$f > mochawesome-report/$f
      fi

      rm -f mochawesome-report/_$f
      
      # If the file is the final minified report and there are no skipped tests, then proceed
      isFullReport=$(echo $f | grep -cim1 "report.json")
      echo "isFullReport " $isFullReport

      if (( $boolSkipping == false && $isFullReport == 1 )); then
         echo -e "--Uploading full report $f to BigQuery Table\n"
         bq load --autodetect --source_format=NEWLINE_DELIMITED_JSON $dataStore.$tblFullReport mochawesome-report/$f
      # Otherwise upload only spec reports, not the final report
      else
         echo -e "--Uploading spec report $f to BigQuery Table\n"
         bq load --autodetect --source_format=NEWLINE_DELIMITED_JSON $dataStore.$fname mochawesome-report/$f
      fi
   else
      echo "File $f has been marked as pending. This will bypass uploading the aggregate report."
      boolSkipping=true
   fi
done
exit