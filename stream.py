# -*- coding: utf-8 -*-
from TwitterAPI import TwitterAPI
import sys
import os
import codecs
import json
import argparse
import gzip
from time import gmtime, strftime

def openfile(mydate,f):
    mydatenew = strftime("%Y-%m-%d/%H/%M", gmtime())
    myfile = args.o + '/' + mydatenew + '/' + args.l + '.gz'
    print(myfile)
    if (mydatenew != mydate) :
        if mydate != '': f.close()
        os.makedirs(os.path.dirname(myfile), exist_ok=True)
        f = gzip.open(myfile , "w")
        mydate = mydatenew
    return mydate,f

parser = argparse.ArgumentParser(description='Twitter streamer.')
parser.add_argument("-v", action="count", default=0, help='verbose output')
parser.add_argument('-l', action='store', required=True, help='language of tweets streamed (Ex: {en,fr,ar})')
parser.add_argument('-k', action='store', required=True, help='file with Twitter keys (one key per line)')
parser.add_argument('-t', action='store', required=True, help='file with term keywords (one term per line)')
parser.add_argument('-o', action='store', required=True, help='option file (default is STDOUT)')
args = parser.parse_args()

KEYS = [line.rstrip('\n') for line in open(args.k)]
if len(KEYS)!=4 : sys.exit('error: keys file should contain 4 entries')
if args.v : print >> sys.stderr, "KEYS: \t"+"\n\t".join(KEYS)

TERMS = [line.rstrip('\n') for line in codecs.open(args.t, "r", "utf-8")]
if len(TERMS)==0 or len(TERMS)>400 : sys.exit('error: terms file should contain [1,400) entries')
if args.v : print >> sys.stderr, "TERMS:\t"+"\n\t".join(TERMS)

if args.v : print >> sys.stderr, "LANG: \t"+args.l

mydate,f = openfile("",0)
api = TwitterAPI(KEYS[0],KEYS[1],KEYS[2],KEYS[3])
r = api.request('statuses/filter', {'track': ",".join(TERMS)})
if args.l : r = api.request('statuses/filter', {'track': ",".join(TERMS), 'language': args.l})

for tweet in r.get_iterator() :
    mydate,f = openfile(mydate,f)
    json_str = json.dumps( tweet, ensure_ascii='True', sort_keys=True, separators=(',',': ') ) + '\n'
    json_bytes = json_str.encode('utf-8')
    f.write(json_bytes)
#    f.write ( json.dumps( tweet, ensure_ascii='True', sort_keys=True, separators=(',',': ') ) + "\n" )

    
