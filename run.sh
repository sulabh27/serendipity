#/usr/bin/bash
docker run   -v /Users/sulabhagarwal/Desktop/serendipity/perl/data.xlsx:/app/data.xlsx   -v /Users/sulabhagarwal/Desktop/serendipity/perl/output:/app/pdf   -v /Users/sulabhagarwal/Desktop/serendipity/perl/output/students:/app/pdf/students   -v //Users/sulabhagarwal/Desktop/serendipity/perl/output/teachers:/app/pdf/teachers   -v //Users/sulabhagarwal/Desktop/serendipity/perl/output/parents:/app/pdf/parents   sulabh27/seren-app:1.1
