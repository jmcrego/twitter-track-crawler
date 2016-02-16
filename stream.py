# -*- coding: utf-8 -*-
from TwitterAPI import TwitterAPI
import sys
import json
import argparse

parser = argparse.ArgumentParser(description='Twitter streamer.')
parser.add_argument('-v', help='verbose output', action='count')
parser.add_argument('-d', help='dump json file', action='count')
parser.add_argument('-l', help='language', action='store')
parser.add_argument('-k', help='file with Twitter keys (one key per line)', action='store')
parser.add_argument('-t', help='file with term keywords (one term per line)', action='store')
args = parser.parse_args()

n=0
nok=0
nko=0

#########################################################################
### DUMP ################################################################
#########################################################################

if args.d :
    for line in sys.stdin :
        n += 1
        item = json.loads(line)
        if 'retweeted_status' in item : continue
        if not 'id_str' in item : continue
        item['text'] = item['text'].replace('\n', unicode('✪','utf-8'))
        item['text'] = item['text'].replace('\r', unicode('✪','utf-8'))
        item['text'] = item['text'].replace('\t', unicode('❂','utf-8'))
        try : 
            print(item['id_str']+"\t"+item['created_at']+"\t"+item['text'])
            nok += 1
        except Exception, e : 
            print >> sys.stderr, "error "+str(e)+": line="+str(n)
            nko += 1
    sys.exit('Done! '+str(nok)+ ' tweets dumped, '+str(nko)+' tweets missed, '+str(n)+' lines')

#########################################################################
### STREAM ##############################################################
#########################################################################

if not args.k : sys.exit('error: missing -k option')
KEYS = [line.rstrip('\n') for line in open(args.k)]
if len(KEYS)!=4 : sys.exit('error: keys file should contain 4 entries')
if args.v : print >> sys.stderr, "KEYS: \t"+"\n\t".join(KEYS)

if not args.t : sys.exit('error: missing -t option')
TERMS = [line.rstrip('\n') for line in open(args.t)]
if len(TERMS)==0 or len(TERMS)>400 : sys.exit('error: terms file should contain [1,400) entries')
if args.v : print >> sys.stderr, "TERMS:\t"+"\n\t".join(TERMS)

if not args.l : sys.exit('error: missing -l option')
LANG = args.l
if LANG!='en' and LANG!='fr' and LANG!='ar' : sys.exit('error: allowed languages are {\'en\',\'fr\',\'ar\'}')
if args.v : print >> sys.stderr, "LANG: \t"+LANG

api = TwitterAPI(KEYS[0],KEYS[1],KEYS[2],KEYS[3])
r = api.request('statuses/filter', {'track': ",".join(TERMS), 'language': LANG})
for tweet in r:
    n += 1
    if not 'id_str' in tweet : continue
    if not 'created_at' in tweet : continue
    if not 'text' in tweet : continue
    if 'retweeted_status' in tweet : continue
    try : 
        print( json.dumps( tweet, ensure_ascii='True', sort_keys=True, separators=(',',': ') ) )
        nok += 1
    except Exception, e : 
        print >> sys.stderr, "error "+str(e)+": line="+str(n)
        nko += 1

sys.exit('Done! '+str(nok)+ ' tweets streamed, '+str(nko)+' tweets missed, '+str(n)+' lines')
