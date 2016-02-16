# -*- coding: utf-8 -*-
import json
import sys

nline=0
for line in sys.stdin :
        nline += 1
        item = json.loads(line);
        if 'retweeted_status' in item : continue
        if not 'id_str' in item : continue
        item['text'].replace('\n', unicode('✪','utf-8')).replace('\t', unicode('❂','utf-8'))
        try:
            print(item['id_str']+"\t"+item['created_at']+"\t"+item['text'])
        except UnicodeEncodeError:
            print >> sys.stderr, "bad string at nline="+str(nline)
            


