# -*- coding: utf-8 -*-
import sys
import json
import argparse

parser = argparse.ArgumentParser(description='Twitter dumper.')
parser.add_argument("-v", help='verbose output', action="count", default=0)
parser.add_argument('do', choices=['id', 'text', 'user', 'time', 'ents'], metavar='STRING', nargs='+', help='tweet field to dump {id, text, user, time, ents}')
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

    ents = []
    if 'ents' in args.do:
        if 'entities' in tweet and 'hashtags' in tweet['entities'] :
            for e in tweet['entities']['hashtags'] :
                ent = []
                ent.append(e['indices'][0])
                ent.append(e['indices'][1])
                ent.append('#'+e['text'])
                ents.append(ent);
        if 'entities' in tweet and 'user_mentions' in tweet['entities'] :
            for e in tweet['entities']['user_mentions'] :
                ent = []
                ent.append(e['indices'][0])
                ent.append(e['indices'][1])
                ent.append('@'+e['screen_name'])
                ents.append(ent);
        if 'entities' in tweet and 'urls' in tweet['entities'] :
            for e in tweet['entities']['urls'] :
                ent = []
                ent.append(e['indices'][0])
                ent.append(e['indices'][1])
                ent.append(e['url'])
                ents.append(ent);
        if 'entities' in tweet and 'symbols' in tweet['entities'] :
            for e in tweet['entities']['symbols'] :
                ent = []
                ent.append(e['indices'][0])
                ent.append(e['indices'][1])
                ent.append(e['text'])
                ents.append(ent);

    ents.sort(key=lambda x: int(x[0]),reverse=True)

    message = tweet['text']
    Ents = []
    for ent in ents :
        first = ent[0]
        last = ent[1]
        text = ent[2]
        message = message[:first] + 'TwItTeReNtItY' + message[last:]
        Ents.insert(0, text)

    message = message.replace('\n', unicode('✪','utf-8'))
    message = message.replace('\r', unicode('✪','utf-8'))
    message = message.replace('\t', unicode('❂','utf-8'))

    out = []
    for do in args.do :
        if do == 'text' : 
            out.append(message)
        if do == 'user' : 
            out.append(tweet['user']['screen_name'])
        if do == 'time' : 
            out.append(tweet['created_at'])
        if do == 'id' : 
            out.append(tweet['id_str'])
        if do == 'ents' : 
            out.append(' '.join(Ents))

    try : 
        print('\t'.join(out).encode('utf-8'))
        nok += 1
    except Exception, e : 
        if args.v : print >> sys.stderr, "error "+str(e)+": line="+str(n)

sys.exit('Done! dumped '+str(nok)+ ' out of '+str(n)+' tweets')

