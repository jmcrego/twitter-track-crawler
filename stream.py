# -*- coding: utf-8 -*-
from TwitterAPI import TwitterAPI
import sys
import json
import argparse

parser = argparse.ArgumentParser(description='Twitter streamer.')
parser.add_argument("-v", action="count", default=0,                  help='verbose output')
parser.add_argument('-l', action='store', choices=['en', 'fr', 'ar'], help='language')
parser.add_argument('-k', action='store',                             help='file with Twitter keys (one key per line)')
parser.add_argument('-t', action='store',                             help='file with term keywords (one term per line)')
args = parser.parse_args()

KEYS = [line.rstrip('\n') for line in open(args.k)]
if len(KEYS)!=4 : sys.exit('error: keys file should contain 4 entries')
if args.v : print >> sys.stderr, "KEYS: \t"+"\n\t".join(KEYS)
TERMS = [line.rstrip('\n') for line in open(args.t)]
if len(TERMS)==0 or len(TERMS)>400 : sys.exit('error: terms file should contain [1,400) entries')
if args.v : print >> sys.stderr, "TERMS:\t"+"\n\t".join(TERMS)
LANG = args.l
if args.v : print >> sys.stderr, "LANG: \t"+LANG

n=0
nok=0
try : 
    api = TwitterAPI(KEYS[0],KEYS[1],KEYS[2],KEYS[3])
    r = api.request('statuses/filter', {'track': ",".join(TERMS), 'language': LANG})
    for tweet in r:
        n += 1
        if not 'id_str' in tweet : continue
        if not 'created_at' in tweet : continue
        if not 'text' in tweet : continue
        if 'retweeted_status' in tweet : continue
        print( json.dumps( tweet, ensure_ascii='True', sort_keys=True, separators=(',',': ') ) )
        nok += 1

except Exception, e : 
    if args.v : print >> sys.stderr, "error "+str(e)+": line="+str(n)

sys.exit('Done! processed '+str(nok)+ ' out of '+str(n)+' tweets')
