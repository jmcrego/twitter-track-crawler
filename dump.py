# -*- coding: utf-8 -*-
import sys
import json
import argparse

parser = argparse.ArgumentParser(description='Twitter streamer.')
parser.add_argument("-v", "--verbose", help='verbose output', action="count", default=0)
args = parser.parse_args()

n=0
nok=0

for line in sys.stdin :
    n += 1
    try :
        item = json.loads(line)
    except Exception, e :
        if args.v : print >> sys.stderr, "error "+str(e)+": line="+str(n)
    if 'retweeted_status' in item : continue
    if not 'id_str' in item : continue
    if not 'user' in item or not 'screen_name' in item['user'] : continue
    item['text'] = item['text'].replace('\n', unicode('✪','utf-8'))
    item['text'] = item['text'].replace('\r', unicode('✪','utf-8'))
    item['text'] = item['text'].replace('\t', unicode('❂','utf-8'))
    try : 
        print(item['id_str']+"\t"+item['created_at']+"\t"+item['user']['screen_name']+"\t"+item['text'])
        nok += 1
    except Exception, e : 
        if args.v : print >> sys.stderr, "error "+str(e)+": line="+str(n)

sys.exit('Done! dumped '+str(nok)+ ' out of '+str(n)+' tweets')

