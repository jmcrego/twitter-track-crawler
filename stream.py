# -*- coding: utf-8 -*-
from TwitterAPI import TwitterAPI
import sys
import json
import argparse
from time import gmtime, strftime

parser = argparse.ArgumentParser(description='Twitter streamer.')
parser.add_argument("-v", action="count", default=0, help='verbose output')
parser.add_argument('-l', action='store', help='language of tweets streamed (Ex: {en,fr,ar})')
parser.add_argument('-k', action='store', help='file with Twitter keys (one key per line)')
parser.add_argument('-t', action='store', help='file with term keywords (one term per line)')
parser.add_argument('-o', action='store', help='option file (default is STDOUT)')
args = parser.parse_args()

KEYS = [line.rstrip('\n') for line in open(args.k)]
if len(KEYS)!=4 : sys.exit('error: keys file should contain 4 entries')
if args.v : print >> sys.stderr, "KEYS: \t"+"\n\t".join(KEYS)
TERMS = [line.rstrip('\n') for line in open(args.t)]
if len(TERMS)==0 or len(TERMS)>400 : sys.exit('error: terms file should contain [1,400) entries')
if args.v : print >> sys.stderr, "TERMS:\t"+"\n\t".join(TERMS)
LANG = args.l
if args.v : print >> sys.stderr, "LANG: \t"+LANG

if args.o :
    mydate=strftime("%Y-%m-%d_%Hh", gmtime())
    f = open(args.o + "." + mydate , 'a')
    mydateprev=mydate

api = TwitterAPI(KEYS[0],KEYS[1],KEYS[2],KEYS[3])
r = api.request('statuses/filter', {'track': ",".join(TERMS), 'language': LANG})
for tweet in r :
    mydate=strftime("%Y-%m-%d_%Hh", gmtime())
    if args.o :
        if (mydate != mydateprev) :
            f.close()
            f = open(args.o + "." + mydate , 'a')
            mydateprev = mydate
        f.write ( json.dumps( tweet, ensure_ascii='True', sort_keys=True, separators=(',',': ') ) + "\n" )
    else :
        print json.dumps( tweet, ensure_ascii='True', sort_keys=True, separators=(',',': ') )

    
