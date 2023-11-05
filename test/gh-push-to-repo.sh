#! /bin/bash
for i in {1..5}
do
  echo "Test $i" >> README.md
  git add README.md
  git commit -m "Test $i" README.md
  git push 
  sleep 6
done
