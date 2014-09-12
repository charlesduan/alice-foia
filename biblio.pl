#!/usr/bin/perl -w

$format = "http://ops.epo.org/3.1/rest-services/family/publication/epodoc/US%010d/biblio";

while (<>) {
    chomp;
    print "\n*** $_\n\n";
    unless (-f "fam-$_.xml" && -s "fam-$_.xml") {
        system 'wget', '-O', "fam-$_.xml", sprintf($format, $_);
        sleep 10;
    }
}
