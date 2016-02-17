# -*- coding: utf-8 -*-
import sys
import json
import argparse

parser = argparse.ArgumentParser(description='Twitter dumper.')
parser.add_argument("-v", help='verbose output', action="count", default=0)
parser.add_argument('do', choices=['id', 'text', 'user', 'time', 'geo'], metavar='STRING', nargs='+', help='tweet field to dump {id, text, user, time, geo}')
args = parser.parse_args()

n = 0
nok = 0
for line in sys.stdin :
    n += 1
    try :
        tweet = json.loads(line)
    except Exception, e :
        if args.v : print >> sys.stderr, "error "+str(e)+": line="+str(n)
        continue

    if not 'id_str' in tweet : continue
    if not 'created_at' in tweet : continue
    if not 'text' in tweet : continue
    if 'retweeted_status' in tweet : continue
    if not 'user' in tweet or not 'screen_name' in tweet['user'] : continue

    out = []
    for do in args.do :
        if do == 'geo' : 
            geo = []
#            if 'place' in tweet and 'id' in tweet['place'] : geo.append(tweet['place']['id'])
#            if 'place' in tweet and 'full_name' in tweet['place'] : geo.append(tweet['place']['full_name'])
#            if len(geo)==0 : geo.append('-')
#            out.append(':'.join(geo))
#OR
#            if 'place' in tweet :
#                if 'attributes' in tweet['place'] : del tweet['place']['attributes']
#                if 'bounding_box' in tweet['place'] and 'type' in tweet['place']['bounding_box'] : del tweet['place']['bounding_box']['type']
#            out.append(json.dumps( tweet['place'], ensure_ascii='True', sort_keys=True, separators=(',',': ') ) )
        if do == 'text' : 
            tweet['text'] = tweet['text'].replace('\n', unicode('✪','utf-8'))
            tweet['text'] = tweet['text'].replace('\r', unicode('✪','utf-8'))
            tweet['text'] = tweet['text'].replace('\t', unicode('❂','utf-8'))
            out.append(tweet['text'])
        if do == 'user' : out.append(tweet['user']['screen_name'])
        if do == 'time' : out.append(tweet['created_at'])
        if do == 'id' : out.append(tweet['id_str'])

    try : 
        print('\t'.join(out).encode('utf-8'))
        nok += 1
    except Exception, e : 
        if args.v : print >> sys.stderr, "error "+str(e)+": line="+str(n)

sys.exit('Done! dumped '+str(nok)+ ' out of '+str(n)+' tweets')

