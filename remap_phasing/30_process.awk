NR == 1 {
  print "ID_1 ID_2 missing" > sampleFile
  print "0 0 0" > sampleFile
  sampleCount = 0
  for(i=5;i<=NF;i+=1){
    print $i,$i,0 > sampleFile
    sampleCount += 1
  }
} 

NR > 1 {

  ORS=" ";
  print chr, $1, $2, substr($3,1,1), substr($3,2,1);
  for(i=0;i<sampleCount;i+=1){
    x = 4 + i * 4
    print $x,$(x+2),$(x+1)
  }
  ORS="";
  print "\n"
}
