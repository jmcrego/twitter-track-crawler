# -*- coding: utf-8 -*-
from TwitterAPI import TwitterAPI
import sys
import json
import argparse

parser = argparse.ArgumentParser(description='Twitter streamer.')
parser.add_argument('-v', help='verbose output', action='count')
parser.add_argument('-l', help='language', action="store", required=True)
parser.add_argument('-k', help='file with Twitter keys (one key per line)', action="store", required=True)
parser.add_argument('-t', help='file with term keywords (one term per line)', action="store", required=True)
args = parser.parse_args()

KEYS = [line.rstrip('\n') for line in open(args.k)]
if len(KEYS)!=4 : sys.exit('error: keys file should contain 4 entries')
if args.v : print >> sys.stderr, "KEYS: \t"+"\n\t".join(KEYS)

TERMS = [line.rstrip('\n') for line in open(args.t)]
if len(TERMS)==0 or len(TERMS)>400 : sys.exit('error: terms file should contain [1,400) entries')
if args.v : print >> sys.stderr, "TERMS:\t"+"\n\t".join(TERMS)

LANG = args.l
if LANG!='en' and LANG!='fr' and LANG!='ar' : sys.exit('error: allowed languages are {\'en\',\'fr\',\'ar\'}')
if args.v : print >> sys.stderr, "LANG: \t"+LANG

#sys.exit('c\'est fini')

api = TwitterAPI(KEYS[0],KEYS[1],KEYS[2],KEYS[3])
r = api.request('statuses/filter', {'track': ",".join(TERMS), 'language': LANG})
for tweet in r:
    if not 'id_str' in tweet : continue
    if 'retweeted_status' in tweet : continue
    print( json.dumps(tweet, ensure_ascii='True', sort_keys=True, separators=(',',': ')))
#    print( json.dumps(tweet, ensure_ascii='True', sort_keys=True, indent=1, separators=(',',': ')))
#    sys.exit('c\'est fini')
